import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:invoiceflow/services/subscription_service.dart';
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

  // Razorpay API keys (these should be in environment variables in production)
  // For now, using test keys - REPLACE WITH YOUR KEYS
  static const String _razorpayKeyId = 'rzp_test_1234567890'; // REPLACE THIS
  static const String _razorpayKeySecret = 'YOUR_SECRET_KEY'; // REPLACE THIS

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

  /// Create and open subscription payment
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

    var options = {
      'key': _razorpayKeyId,
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
        'color': '#2196F3', // Blue theme
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

  /// Verify payment and upgrade subscription
  Future<void> verifyAndUpgradeSubscription({
    required String paymentId,
    required String plan,
  }) async {
    try {
      // In production, you should verify the payment signature with your backend
      // For now, we'll trust the client-side success callback
      // TODO: Add server-side verification

      // Upgrade subscription
      await SubscriptionService.instance.upgradeToPremium(
        paymentId,
        plan: plan,
      );

      debugPrint('Subscription upgraded successfully');
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
