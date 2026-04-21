import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoiceflow/models/subscription_model.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
        // Doc is missing — delegate creation to the Cloud Function so the
        // Firestore `allow write: if false` rule on subscription documents is
        // satisfied. Never write directly from the client here.
        try {
          await _functions
              .httpsCallable('initializeUserSubscription')
              .call<Map<String, dynamic>>();

          // Re-read after the Cloud Function writes the document.
          final created = await _subscriptionRef!.get();
          if (created.exists) return SubscriptionModel.fromFirestore(created);
        } on FirebaseFunctionsException catch (e) {
          // Function unreachable (no network, cold-start timeout, not yet
          // deployed). Return an in-memory free-tier model so the app stays
          // usable on first launch. Nothing is written to Firestore — the
          // Function will be retried on the next getCurrentSubscription() call
          // (app restart, SubscriptionProvider.refresh(), etc.).
          print(
            'initializeUserSubscription unavailable '
            '(${e.code}): ${e.message}. Using in-memory free tier.',
          );
        } catch (e) {
          // Unexpected error (e.g. auth race on very first launch).
          // Same safe fallback — in-memory model, no Firestore write.
          print(
            'initializeUserSubscription error: $e. Using in-memory free tier.',
          );
        }

        // Fallback: return an in-memory free-tier model. This object is not
        // persisted. The Provider layer will call getCurrentSubscription() again
        // after the next auth state change or explicit refresh, at which point
        // the Cloud Function should succeed and the real document will be read.
        return SubscriptionModel.createFreeTier();
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

  /// Initialize subscription for new user.
  ///
  /// Delegates to the [initializeUserSubscription] Cloud Function so that the
  /// Firestore `allow write: if false` rule on subscription documents is
  /// satisfied. The function is idempotent (safe to call on every launch).
  Future<void> initializeNewUserSubscription() async {
    if (_currentUserId == null) return;

    try {
      await _functions
          .httpsCallable('initializeUserSubscription')
          .call<Map<String, dynamic>>();
    } on FirebaseFunctionsException catch (e) {
      throw SubscriptionException('Failed to initialize subscription: ${e.message}');
    } catch (e) {
      throw SubscriptionException('Failed to initialize subscription: $e');
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

  /// Cancel subscription (downgrade to free at end of period).
  ///
  /// Delegates to the [cancelSubscription] Cloud Function. The function
  /// validates that an active premium or trial subscription exists before
  /// writing. Optionally pass a [reason] string that will be stored in the
  /// subscription_events document.
  Future<void> cancelSubscription({String? reason}) async {
    if (_currentUserId == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      await _functions.httpsCallable('cancelSubscription').call<Map<String, dynamic>>(
        reason != null ? {'reason': reason} : null,
      );
    } on FirebaseFunctionsException catch (e) {
      throw SubscriptionException('Failed to cancel: ${e.message}');
    } catch (e) {
      throw SubscriptionException('Failed to cancel: $e');
    }
  }

  /// Reactivate cancelled subscription.
  ///
  /// TODO(CF): Implement a `reactivateSubscription` Cloud Function before
  /// exposing this in the UI. The direct Firestore write below is blocked by
  /// the `allow write: if false` rule on subscription documents.
  /// Until the CF exists, this method must not be called — the UI should not
  /// surface a reactivation button to the user.
  ///
  /// See: .claude/memory/open-questions.md — add a new issue when scheduling
  /// this work.
  Future<void> reactivateSubscription() async {
    // No-op until reactivateSubscription Cloud Function is built and deployed.
    // Calling this method will silently succeed — it will not write to Firestore
    // and will not throw, so any accidental call site does not crash the app.
    throw SubscriptionException(
      'reactivateSubscription is not yet available. '
      'A Cloud Function implementation is required before this can be used.',
    );
  }

  // USAGE TRACKING

  /// Decrement OCR scans (for free tier).
  ///
  /// @deprecated The decrement is now performed server-side inside the
  /// [processOCR] Cloud Function using a Firestore transaction, which closes
  /// the race-condition window that existed in this client-side implementation.
  /// This method is a no-op and will be removed once all callers (OCRService,
  /// SubscriptionProvider) are confirmed to rely solely on the server path.
  ///
  /// Callers in this codebase:
  ///   - lib/services/ai/ocr_service.dart  (line ~95) — still calls this after
  ///     the HTTP OCR function returns, but processOCR now handles it on the
  ///     server, so the call here is redundant. OCRService should remove step 8
  ///     in a follow-up cleanup.
  ///   - lib/providers/subscription_provider.dart (decrementOCRScans wrapper) —
  ///     similarly redundant; can be removed once OCRService is cleaned up.
  @Deprecated('Decrement is now handled server-side in processOCR Cloud Function. '
      'Remove this call from OCRService and SubscriptionProvider.')
  Future<void> decrementOCRScans() async {
    // No-op: the processOCR Cloud Function decrements ocrScansRemaining
    // atomically via a Firestore transaction after a successful OCR response.
  }

  /// Increment AI insights count.
  ///
  /// TODO(CF): Move this counter increment into the [generateBusinessInsights]
  /// Cloud Function so the write happens server-side. The direct Firestore
  /// write is blocked by the subscription rule. No-op until then.
  Future<void> incrementAIInsightsCount() async {
    // No-op: counter increment will be handled inside generateBusinessInsights
    // Cloud Function in a follow-up task.
  }

  /// Increment risk predictions count.
  ///
  /// TODO(CF): Move into [predictPaymentRisk] Cloud Function. No-op until then.
  Future<void> incrementRiskPredictionsCount() async {
    // No-op: counter increment will be handled inside predictPaymentRisk
    // Cloud Function in a follow-up task.
  }

  /// Increment inventory forecasts count.
  ///
  /// TODO(CF): Move into [forecastInventory] Cloud Function. No-op until then.
  Future<void> incrementInventoryForecastsCount() async {
    // No-op: counter increment will be handled inside forecastInventory
    // Cloud Function in a follow-up task.
  }

  /// Reset monthly usage.
  ///
  /// The authoritative reset is performed by the scheduled Cloud Function
  /// that runs at UTC 00:00 on the 1st of each month (Asia/Kolkata timezone).
  /// This client-side method is a no-op — calling it from the client would be
  /// blocked by the `allow write: if false` subscription rule anyway.
  Future<void> resetMonthlyUsage() async {
    // No-op: handled by the scheduled Cloud Function (monthlyUsageReset).
    // Do not re-add a direct Firestore write here.
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

  /// Start free trial (7 days).
  ///
  /// Delegates to the [startFreeTrial] Cloud Function. The function enforces:
  ///  - trial has not already been used (trialEndDate never set)
  ///  - user is not already on an active premium plan
  /// Throws [SubscriptionException] for both business-rule violations and errors.
  Future<void> startFreeTrial() async {
    if (_currentUserId == null) {
      throw SubscriptionException('User not authenticated');
    }

    try {
      await _functions
          .httpsCallable('startFreeTrial')
          .call<Map<String, dynamic>>();
    } on FirebaseFunctionsException catch (e) {
      // Surface the server-side business-rule messages unchanged so callers
      // (and the UI) receive the same strings as before.
      throw SubscriptionException('Failed to start trial: ${e.message}');
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

  /// Check and expire trial if needed.
  ///
  /// The authoritative expiry is written by the scheduled Cloud Function
  /// (dailySubscriptionCheck) that runs at UTC 02:00 each day. That function
  /// uses the Admin SDK and is not blocked by Firestore security rules.
  ///
  /// This client-side method is a no-op. The `allow write: if false` rule on
  /// subscription documents blocks any write attempt from the client anyway.
  /// The UI will see the correct expired state once the scheduled function runs
  /// and the real-time stream in [subscriptionStream] delivers the update.
  Future<void> checkAndExpireTrial() async {
    // No-op: handled by the scheduled Cloud Function (dailySubscriptionCheck).
    // Do not re-add a direct Firestore write here.
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

  /// Check if subscription has expired and update status.
  ///
  /// The authoritative expiry is written by the scheduled Cloud Function
  /// (dailySubscriptionCheck) that runs at UTC 02:00 each day. That function
  /// uses the Admin SDK and is not blocked by Firestore security rules.
  ///
  /// This client-side method is a no-op. The `allow write: if false` rule on
  /// subscription documents blocks any write attempt from the client anyway.
  Future<void> checkAndExpireSubscription() async {
    // No-op: handled by the scheduled Cloud Function (dailySubscriptionCheck).
    // Do not re-add a direct Firestore write here.
  }
}
