import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoiceflow/models/subscription_model.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Reference to user's subscription document
  DocumentReference? get _subscriptionRef {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('subscription')
        .doc('current');
  }

  // CORE SUBSCRIPTION MANAGEMENT

  /// Get current subscription for the logged-in user
  Future<SubscriptionModel> getCurrentSubscription() async {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      final doc = await _subscriptionRef!.get();

      if (!doc.exists) {
        // Create default free tier subscription for new users
        final freeSub = SubscriptionModel.createFreeTier();
        await _subscriptionRef!.set(freeSub.toFirestore());
        return freeSub;
      }

      return SubscriptionModel.fromFirestore(doc);
    } catch (e) {
      throw SubscriptionException('Failed to get subscription: $e');
    }
  }

  /// Stream of subscription updates
  Stream<SubscriptionModel> subscriptionStream() {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    return _subscriptionRef!.snapshots().map((doc) {
      if (!doc.exists) {
        return SubscriptionModel.createFreeTier();
      }
      return SubscriptionModel.fromFirestore(doc);
    });
  }

  /// Initialize subscription for new user
  Future<void> initializeNewUserSubscription() async {
    if (_currentUserId == null) return;

    final doc = await _subscriptionRef!.get();
    if (!doc.exists) {
      final freeSub = SubscriptionModel.createFreeTier();
      await _subscriptionRef!.set(freeSub.toFirestore());
    }
  }

  /// Upgrade to premium subscription
  Future<void> upgradeToPremium(
    String paymentId, {
    String plan = 'monthly', // 'monthly' or 'yearly'
  }) async {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      final currentSub = await getCurrentSubscription();
      final now = DateTime.now();

      // Calculate end date based on plan
      final endDate = plan == 'yearly'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      final premiumSub = currentSub.copyWith(
        tier: SubscriptionTier.premium,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        trialEndDate: null, // Clear trial if was in trial
        subscriptionId: paymentId,
        features: SubscriptionFeatures.premiumTier(),
        usageLimits: UsageLimits.premiumTier(),
        updatedAt: now,
      );

      await _subscriptionRef!.update(premiumSub.toFirestore());

      // Track upgrade event
      await _trackSubscriptionEvent('subscription_upgraded', {
        'plan': plan,
        'payment_id': paymentId,
        'previous_tier': currentSub.tier.name,
      });
    } catch (e) {
      throw SubscriptionException('Failed to upgrade: $e');
    }
  }

  /// Cancel subscription (downgrade to free at end of period)
  Future<void> cancelSubscription() async {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      final currentSub = await getCurrentSubscription();

      final cancelledSub = currentSub.copyWith(
        status: SubscriptionStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await _subscriptionRef!.update(cancelledSub.toFirestore());

      // Track cancellation
      await _trackSubscriptionEvent('subscription_cancelled', {
        'tier': currentSub.tier.name,
        'days_remaining': currentSub.daysRemaining,
      });
    } catch (e) {
      throw SubscriptionException('Failed to cancel: $e');
    }
  }

  /// Reactivate cancelled subscription
  Future<void> reactivateSubscription() async {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      final currentSub = await getCurrentSubscription();

      if (currentSub.status != SubscriptionStatus.cancelled) {
        throw SubscriptionException('Subscription is not cancelled');
      }

      final reactivatedSub = currentSub.copyWith(
        status: SubscriptionStatus.active,
        updatedAt: DateTime.now(),
      );

      await _subscriptionRef!.update(reactivatedSub.toFirestore());
    } catch (e) {
      throw SubscriptionException('Failed to reactivate: $e');
    }
  }

  // USAGE TRACKING

  /// Decrement OCR scans (for free tier)
  Future<void> decrementOCRScans() async {
    if (_subscriptionRef == null) return;

    try {
      final currentSub = await getCurrentSubscription();

      // Premium has unlimited (-1), don't decrement
      if (currentSub.features.ocrScansRemaining == -1) return;

      final newCount = (currentSub.features.ocrScansRemaining - 1).clamp(0, 999);

      await _subscriptionRef!.update({
        'features.ocrScansRemaining': newCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Failed to decrement OCR scans: $e');
    }
  }

  /// Increment AI insights count
  Future<void> incrementAIInsightsCount() async {
    if (_subscriptionRef == null) return;

    try {
      await _subscriptionRef!.update({
        'features.aiInsightsGenerated': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Failed to increment insights count: $e');
    }
  }

  /// Increment risk predictions count
  Future<void> incrementRiskPredictionsCount() async {
    if (_subscriptionRef == null) return;

    try {
      await _subscriptionRef!.update({
        'features.riskPredictionsUsed': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Failed to increment risk predictions: $e');
    }
  }

  /// Increment inventory forecasts count
  Future<void> incrementInventoryForecastsCount() async {
    if (_subscriptionRef == null) return;

    try {
      await _subscriptionRef!.update({
        'features.inventoryForecastsGenerated': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Failed to increment forecasts: $e');
    }
  }

  /// Reset monthly usage (called by Cloud Function on 1st of month)
  Future<void> resetMonthlyUsage() async {
    if (_subscriptionRef == null) return;

    try {
      final currentSub = await getCurrentSubscription();

      final resetFeatures = currentSub.tier == SubscriptionTier.free
          ? SubscriptionFeatures.freeTier() // Reset to 5 for free tier
          : currentSub.features.copyWith(
              aiInsightsGenerated: 0,
              riskPredictionsUsed: 0,
              inventoryForecastsGenerated: 0,
            );

      await _subscriptionRef!.update({
        'features': resetFeatures.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Failed to reset monthly usage: $e');
    }
  }

  /// Get current month usage statistics
  Future<Map<String, int>> getCurrentMonthUsage() async {
    try {
      final currentSub = await getCurrentSubscription();
      return {
        'ocrScansRemaining': currentSub.features.ocrScansRemaining,
        'aiInsightsGenerated': currentSub.features.aiInsightsGenerated,
        'riskPredictionsUsed': currentSub.features.riskPredictionsUsed,
        'inventoryForecastsGenerated':
            currentSub.features.inventoryForecastsGenerated,
      };
    } catch (e) {
      return {};
    }
  }

  // FEATURE GATES

  /// Check if user can access a specific feature
  Future<bool> canAccessFeature(String featureName) async {
    try {
      final currentSub = await getCurrentSubscription();
      return currentSub.canAccessFeature(featureName);
    } catch (e) {
      return false; // Deny access on error
    }
  }

  /// Track feature usage with metadata
  Future<void> trackFeatureUsage(
    String feature,
    Map<String, dynamic> metadata,
  ) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('ai_usage')
          .add({
        'featureType': feature,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
    } catch (e) {
      print('Failed to track feature usage: $e');
    }
  }

  // TRIAL MANAGEMENT

  /// Start free trial (7 days)
  Future<void> startFreeTrial() async {
    if (_subscriptionRef == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      final currentSub = await getCurrentSubscription();

      // Check if already used trial
      if (currentSub.trialEndDate != null) {
        throw SubscriptionException('Trial already used');
      }

      final trialSub = SubscriptionModel.createTrial();
      await _subscriptionRef!.update(trialSub.toFirestore());

      // Track trial start
      await _trackSubscriptionEvent('trial_started', {});
    } catch (e) {
      throw SubscriptionException('Failed to start trial: $e');
    }
  }

  /// Check if trial is available for user
  Future<bool> isTrialAvailable() async {
    try {
      final currentSub = await getCurrentSubscription();
      // Trial available if never used (trialEndDate is null)
      return currentSub.trialEndDate == null;
    } catch (e) {
      return false;
    }
  }

  /// Get days remaining in trial
  Future<int> getDaysRemainingInTrial() async {
    try {
      final currentSub = await getCurrentSubscription();
      return currentSub.trialDaysRemaining;
    } catch (e) {
      return 0;
    }
  }

  /// Check and expire trial if needed
  Future<void> checkAndExpireTrial() async {
    if (_subscriptionRef == null) return;

    try {
      final currentSub = await getCurrentSubscription();

      if (currentSub.status == SubscriptionStatus.trial &&
          currentSub.trialDaysRemaining == 0) {
        // Trial expired, downgrade to free
        final expiredSub = currentSub.copyWith(
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.expired,
          features: SubscriptionFeatures.freeTier(),
          usageLimits: UsageLimits.freeTier(),
          updatedAt: DateTime.now(),
        );

        await _subscriptionRef!.update(expiredSub.toFirestore());

        // Track trial expiration
        await _trackSubscriptionEvent('trial_expired', {});
      }
    } catch (e) {
      print('Failed to check trial expiration: $e');
    }
  }

  // HELPER METHODS

  /// Track subscription-related events
  Future<void> _trackSubscriptionEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('subscription_events')
          .add({
        'event': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'parameters': parameters,
      });
    } catch (e) {
      print('Failed to track subscription event: $e');
    }
  }

  /// Check if subscription has expired and update status
  Future<void> checkAndExpireSubscription() async {
    if (_subscriptionRef == null) return;

    try {
      final currentSub = await getCurrentSubscription();

      if (currentSub.status == SubscriptionStatus.active &&
          currentSub.endDate != null &&
          DateTime.now().isAfter(currentSub.endDate!)) {
        // Subscription expired
        final expiredSub = currentSub.copyWith(
          tier: SubscriptionTier.free,
          status: SubscriptionStatus.expired,
          features: SubscriptionFeatures.freeTier(),
          usageLimits: UsageLimits.freeTier(),
          updatedAt: DateTime.now(),
        );

        await _subscriptionRef!.update(expiredSub.toFirestore());

        // Track expiration
        await _trackSubscriptionEvent('subscription_expired', {});
      }
    } catch (e) {
      print('Failed to check subscription expiration: $e');
    }
  }
}
