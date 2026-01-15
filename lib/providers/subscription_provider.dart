import 'package:flutter/material.dart';
import 'package:invoiceflow/models/subscription_model.dart';
import 'package:invoiceflow/services/subscription_service.dart';
import 'dart:async';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<SubscriptionModel>? _subscriptionStream;

  // Getters
  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Subscription state getters
  bool get isPremium => _subscription?.isPremium ?? false;
  bool get isTrial => _subscription?.isTrial ?? false;
  bool get isActive => _subscription?.isActive ?? false;
  int get daysRemaining => _subscription?.daysRemaining ?? 0;
  int get trialDaysRemaining => _subscription?.trialDaysRemaining ?? 0;

  // Feature access getters
  bool get canUseOCR => _subscription?.canUseOCR() ?? false;
  bool get canUseAIInsights => _subscription?.canUseAIInsights() ?? false;
  bool get canUseRiskPrediction => _subscription?.canUseRiskPrediction() ?? false;
  bool get canUseForecast => _subscription?.canUseForecast() ?? false;

  // Usage stats getters
  int get ocrScansRemaining =>
      _subscription?.features.ocrScansRemaining ?? 0;
  int get aiInsightsGenerated =>
      _subscription?.features.aiInsightsGenerated ?? 0;

  SubscriptionProvider() {
    _initialize();
  }

  /// Initialize and load subscription
  Future<void> _initialize() async {
    await loadSubscription();
    _listenToSubscriptionChanges();
  }

  /// Load subscription from service
  Future<void> loadSubscription() async {
    _setLoading(true);
    _setError(null);

    try {
      _subscription = await SubscriptionService.instance.getCurrentSubscription();

      // Check for expired trial or subscription
      await SubscriptionService.instance.checkAndExpireTrial();
      await SubscriptionService.instance.checkAndExpireSubscription();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscription: $e');
      debugPrint('Error loading subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to real-time subscription updates
  void _listenToSubscriptionChanges() {
    try {
      _subscriptionStream = SubscriptionService.instance
          .subscriptionStream()
          .listen((subscription) {
        _subscription = subscription;
        notifyListeners();
      }, onError: (error) {
        _setError('Subscription stream error: $error');
      });
    } catch (e) {
      debugPrint('Error setting up subscription stream: $e');
    }
  }

  /// Upgrade to premium
  Future<bool> upgradeToPremium(String paymentId, {String plan = 'monthly'}) async {
    _setLoading(true);
    _setError(null);

    try {
      await SubscriptionService.instance.upgradeToPremium(paymentId, plan: plan);
      await loadSubscription(); // Reload to get updated data
      return true;
    } catch (e) {
      _setError('Failed to upgrade: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start free trial
  Future<bool> startFreeTrial() async {
    _setLoading(true);
    _setError(null);

    try {
      await SubscriptionService.instance.startFreeTrial();
      await loadSubscription();
      return true;
    } catch (e) {
      _setError('Failed to start trial: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    _setLoading(true);
    _setError(null);

    try {
      await SubscriptionService.instance.cancelSubscription();
      await loadSubscription();
      return true;
    } catch (e) {
      _setError('Failed to cancel: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if trial is available
  Future<bool> isTrialAvailable() async {
    try {
      return await SubscriptionService.instance.isTrialAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Check feature access with optional dialog display
  Future<bool> checkFeatureAccess(
    String featureName, {
    BuildContext? context,
    bool showDialog = true,
  }) async {
    try {
      final hasAccess =
          await SubscriptionService.instance.canAccessFeature(featureName);

      if (!hasAccess && showDialog && context != null && context.mounted) {
        _showUpgradeDialog(context, featureName);
      }

      return hasAccess;
    } catch (e) {
      return false;
    }
  }

  /// Show upgrade dialog (will be customized in UI layer)
  void _showUpgradeDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: Text(
          _getFeatureLockedMessage(featureName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  /// Get feature-specific locked message
  String _getFeatureLockedMessage(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'ocr':
        if (_subscription?.tier == SubscriptionTier.free &&
            ocrScansRemaining == 0) {
          return 'You\'ve used all 5 free OCR scans this month. Upgrade to Premium for unlimited scans!';
        }
        return 'OCR scanning requires a Premium subscription. Scan receipts instantly and save time!';

      case 'ai_insights':
      case 'insights':
        return 'AI Business Insights are available for Premium users. Get personalized recommendations to grow your business!';

      case 'risk_prediction':
      case 'payment_risk':
        return 'Payment Risk Prediction helps you prioritize collections. Upgrade to Premium to access this feature!';

      case 'forecast':
      case 'inventory_forecast':
        return 'Inventory Forecasting predicts demand and prevents stockouts. Available with Premium subscription!';

      default:
        return 'This feature requires a Premium subscription. Upgrade now to unlock all AI-powered features!';
    }
  }

  /// Decrement OCR scans (called after successful scan)
  Future<void> decrementOCRScans() async {
    try {
      await SubscriptionService.instance.decrementOCRScans();
      // The stream will automatically update the subscription
    } catch (e) {
      debugPrint('Error decrementing OCR scans: $e');
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(
    String feature,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await SubscriptionService.instance.trackFeatureUsage(feature, metadata);
    } catch (e) {
      debugPrint('Error tracking feature usage: $e');
    }
  }

  /// Get usage statistics
  Future<Map<String, int>> getUsageStats() async {
    try {
      return await SubscriptionService.instance.getCurrentMonthUsage();
    } catch (e) {
      return {};
    }
  }

  /// Refresh subscription data
  Future<void> refresh() async {
    await loadSubscription();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    if (value != null) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
