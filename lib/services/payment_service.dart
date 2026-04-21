import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';

class PaymentService {
  static final PaymentService instance = PaymentService._();
  PaymentService._();

  late Razorpay _razorpay;
  bool _isInitialized = false;

  // Callbacks for payment events
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentError;
  Function()? _onExternalWallet;

  // Pricing in INR (paise = rupees * 100)
  static const int MONTHLY_PRICE = 299; // ₹299/month
  static const int YEARLY_PRICE = 2999; // ₹2999/year (save ₹589, 16% off)
  static const int MONTHLY_PRICE_PAISE = MONTHLY_PRICE * 100; // 29900 paise
  static const int YEARLY_PRICE_PAISE = YEARLY_PRICE * 100; // 299900 paise

  // Injected at build time via --dart-define=RAZORPAY_KEY_ID=<key>
  // Dev:  scripts/build.sh dev   (uses rzp_test_* key)
  // Prod: scripts/build.sh prod  (reads RAZORPAY_LIVE_KEY_ID from env)
  // The key secret never lives in the client — verification is server-side.
  static const String _razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  /// Initialize Razorpay
  Future<void> initializeRazorpay({
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentError,
    Function()? onExternalWallet,
  }) async {
    if (_isInitialized) {
      // Update callbacks
      _onPaymentSuccess = onPaymentSuccess;
      _onPaymentError = onPaymentError;
      _onExternalWallet = onExternalWallet;
      return;
    }

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _onPaymentSuccess = onPaymentSuccess;
    _onPaymentError = onPaymentError;
    _onExternalWallet = onExternalWallet;

    _isInitialized = true;
  }

  /// Create a server-side Razorpay order then open checkout.
  ///
  /// Step 1 — calls [createRazorpayOrder] Cloud Function, which POSTs to
  /// Razorpay's Orders API using the key secret stored in Secret Manager.
  /// Returns an orderId from Razorpay.
  ///
  /// Step 2 — opens Razorpay checkout with `order_id` in the options map.
  /// With an orderId present the SDK returns non-null orderId + signature
  /// on success, enabling HMAC-SHA256 verification in [verifyRazorpayPayment].
  Future<void> createSubscriptionOrder({
    required String plan, // 'monthly' or 'yearly'
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    if (!_isInitialized) {
      throw PaymentException('Razorpay not initialized');
    }

    final amount = plan == 'yearly' ? YEARLY_PRICE_PAISE : MONTHLY_PRICE_PAISE;
    final description = plan == 'yearly'
        ? 'InvoiceFlow Premium - Yearly'
        : 'InvoiceFlow Premium - Monthly';

    // Step 1: create order server-side — required for non-null orderId + signature
    final String orderId;
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createRazorpayOrder')
          .call<Map<String, dynamic>>({
        'amount': amount,
        'currency': 'INR',
        'planType': plan,
      });
      orderId = result.data['orderId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException('Failed to create order: ${e.message}');
    } catch (e) {
      throw PaymentException('Failed to create order: $e');
    }

    // Step 2: open checkout with orderId so SDK populates orderId + signature
    final options = {
      'key': _razorpayKeyId,
      'order_id': orderId,
      'amount': amount,
      'name': 'InvoiceFlow',
      'description': description,
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
      'notes': {
        'plan': plan,
        'user_name': userName,
      },
      'theme': {
        'color': '#2196F3',
      },
      'currency': 'INR',
      'send_sms_hash': true,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw PaymentException('Failed to open payment: $e');
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');

    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response);
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    if (_onPaymentError != null) {
      _onPaymentError!(response);
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');

    if (_onExternalWallet != null) {
      _onExternalWallet!();
    }
  }

  /// Verify payment signature server-side and upgrade subscription.
  ///
  /// Calls the [verifyRazorpayPayment] Cloud Function which:
  ///  1. Verifies HMAC-SHA256(orderId|paymentId) against the signature using
  ///     RAZORPAY_KEY_SECRET stored in Secret Manager — the secret never
  ///     touches the client.
  ///  2. Writes the subscription upgrade to Firestore via Admin SDK on success.
  ///
  /// Throws [PaymentException] on signature mismatch or any server error.
  Future<void> verifyAndUpgradeSubscription({
    required String paymentId,
    required String orderId,
    required String signature,
    required String plan,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('verifyRazorpayPayment')
          .call<Map<String, dynamic>>({
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
        'plan': plan,
      });
      debugPrint('Subscription upgraded: paymentId=$paymentId plan=$plan');
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException('Payment verification failed: ${e.message}');
    } catch (e) {
      throw PaymentException('Failed to verify payment: $e');
    }
  }

  /// Handle payment success callback (to be called from UI)
  Future<void> handlePaymentSuccess(
    PaymentSuccessResponse response,
    String plan,
  ) async {
    await verifyAndUpgradeSubscription(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
      plan: plan,
    );
  }

  /// Cleanup Razorpay instance
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }

  /// Get price display string
  static String getPriceDisplay(String plan) {
    if (plan == 'yearly') {
      return '₹$YEARLY_PRICE/year';
    } else {
      return '₹$MONTHLY_PRICE/month';
    }
  }

  /// Get savings display for yearly plan
  static String getYearlySavings() {
    final monthlyCost = MONTHLY_PRICE * 12;
    final savings = monthlyCost - YEARLY_PRICE;
    return 'Save ₹$savings (${((savings / monthlyCost) * 100).toStringAsFixed(0)}% off)';
  }

  /// Calculate price per month for yearly plan
  static String getYearlyPricePerMonth() {
    final perMonth = (YEARLY_PRICE / 12).round();
    return '₹$perMonth/month';
  }
}

/// Exception for payment-related errors
class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}
