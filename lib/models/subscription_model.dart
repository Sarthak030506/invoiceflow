import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, premium }

enum SubscriptionStatus { active, cancelled, expired, trial }

class SubscriptionModel {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final String paymentProvider;
  final String? subscriptionId;
  final SubscriptionFeatures features;
  final UsageLimits usageLimits;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.tier,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.paymentProvider,
    this.subscriptionId,
    required this.features,
    required this.usageLimits,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for subscription state
  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;

  bool get isPremium => tier == SubscriptionTier.premium && isActive;

  bool get isTrial => status == SubscriptionStatus.trial;

  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }

  int get trialDaysRemaining {
    if (trialEndDate == null) return 0;
    final remaining = trialEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Feature access checks
  bool canUseOCR() => features.ocrScansRemaining != 0;

  bool canUseAIInsights() => isPremium;

  bool canUseRiskPrediction() =>
      isPremium && usageLimits.riskPredictionsEnabled;

  bool canUseForecast() => isPremium && usageLimits.inventoryForecastEnabled;

  bool canAccessFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'ocr':
        return canUseOCR();
      case 'ai_insights':
      case 'insights':
        return canUseAIInsights();
      case 'risk_prediction':
      case 'payment_risk':
        return canUseRiskPrediction();
      case 'forecast':
      case 'inventory_forecast':
        return canUseForecast();
      default:
        return false;
    }
  }

  // Factory constructor from Firestore
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      tier: SubscriptionTier.values
          .firstWhere((e) => e.name == data['tier'], orElse: () => SubscriptionTier.free),
      status: SubscriptionStatus.values
          .firstWhere((e) => e.name == data['status'], orElse: () => SubscriptionStatus.active),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      paymentProvider: data['paymentProvider'] ?? 'razorpay',
      subscriptionId: data['subscriptionId'],
      features: SubscriptionFeatures.fromMap(
          data['features'] ?? <String, dynamic>{}),
      usageLimits: UsageLimits.fromMap(
          data['usageLimits'] ?? <String, dynamic>{}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'tier': tier.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'trialEndDate':
          trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'paymentProvider': paymentProvider,
      'subscriptionId': subscriptionId,
      'features': features.toMap(),
      'usageLimits': usageLimits.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create default free tier subscription
  factory SubscriptionModel.createFreeTier() {
    final now = DateTime.now();
    return SubscriptionModel(
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.active,
      startDate: now,
      paymentProvider: 'razorpay',
      features: SubscriptionFeatures.freeTier(),
      usageLimits: UsageLimits.freeTier(),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create trial subscription (7 days)
  factory SubscriptionModel.createTrial() {
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 7));
    return SubscriptionModel(
      tier: SubscriptionTier.premium,
      status: SubscriptionStatus.trial,
      startDate: now,
      trialEndDate: trialEnd,
      endDate: trialEnd,
      paymentProvider: 'razorpay',
      features: SubscriptionFeatures.premiumTier(),
      usageLimits: UsageLimits.premiumTier(),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with method
  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    String? paymentProvider,
    String? subscriptionId,
    SubscriptionFeatures? features,
    UsageLimits? usageLimits,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      features: features ?? this.features,
      usageLimits: usageLimits ?? this.usageLimits,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class SubscriptionFeatures {
  final int ocrScansRemaining; // -1 for unlimited
  final int aiInsightsGenerated;
  final int riskPredictionsUsed;
  final int inventoryForecastsGenerated;

  SubscriptionFeatures({
    required this.ocrScansRemaining,
    required this.aiInsightsGenerated,
    required this.riskPredictionsUsed,
    required this.inventoryForecastsGenerated,
  });

  factory SubscriptionFeatures.fromMap(Map<String, dynamic> map) {
    return SubscriptionFeatures(
      ocrScansRemaining: map['ocrScansRemaining'] ?? 5,
      aiInsightsGenerated: map['aiInsightsGenerated'] ?? 0,
      riskPredictionsUsed: map['riskPredictionsUsed'] ?? 0,
      inventoryForecastsGenerated: map['inventoryForecastsGenerated'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ocrScansRemaining': ocrScansRemaining,
      'aiInsightsGenerated': aiInsightsGenerated,
      'riskPredictionsUsed': riskPredictionsUsed,
      'inventoryForecastsGenerated': inventoryForecastsGenerated,
    };
  }

  factory SubscriptionFeatures.freeTier() {
    return SubscriptionFeatures(
      ocrScansRemaining: 5, // 5 free scans per month
      aiInsightsGenerated: 0,
      riskPredictionsUsed: 0,
      inventoryForecastsGenerated: 0,
    );
  }

  factory SubscriptionFeatures.premiumTier() {
    return SubscriptionFeatures(
      ocrScansRemaining: -1, // Unlimited
      aiInsightsGenerated: 0,
      riskPredictionsUsed: 0,
      inventoryForecastsGenerated: 0,
    );
  }

  SubscriptionFeatures copyWith({
    int? ocrScansRemaining,
    int? aiInsightsGenerated,
    int? riskPredictionsUsed,
    int? inventoryForecastsGenerated,
  }) {
    return SubscriptionFeatures(
      ocrScansRemaining: ocrScansRemaining ?? this.ocrScansRemaining,
      aiInsightsGenerated: aiInsightsGenerated ?? this.aiInsightsGenerated,
      riskPredictionsUsed: riskPredictionsUsed ?? this.riskPredictionsUsed,
      inventoryForecastsGenerated:
          inventoryForecastsGenerated ?? this.inventoryForecastsGenerated,
    );
  }
}

class UsageLimits {
  final int ocrScansPerMonth;
  final int aiInsightsPerMonth;
  final bool riskPredictionsEnabled;
  final bool inventoryForecastEnabled;

  UsageLimits({
    required this.ocrScansPerMonth,
    required this.aiInsightsPerMonth,
    required this.riskPredictionsEnabled,
    required this.inventoryForecastEnabled,
  });

  factory UsageLimits.fromMap(Map<String, dynamic> map) {
    return UsageLimits(
      ocrScansPerMonth: map['ocrScansPerMonth'] ?? 5,
      aiInsightsPerMonth: map['aiInsightsPerMonth'] ?? 0,
      riskPredictionsEnabled: map['riskPredictionsEnabled'] ?? false,
      inventoryForecastEnabled: map['inventoryForecastEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ocrScansPerMonth': ocrScansPerMonth,
      'aiInsightsPerMonth': aiInsightsPerMonth,
      'riskPredictionsEnabled': riskPredictionsEnabled,
      'inventoryForecastEnabled': inventoryForecastEnabled,
    };
  }

  factory UsageLimits.freeTier() {
    return UsageLimits(
      ocrScansPerMonth: 5,
      aiInsightsPerMonth: 0,
      riskPredictionsEnabled: false,
      inventoryForecastEnabled: false,
    );
  }

  factory UsageLimits.premiumTier() {
    return UsageLimits(
      ocrScansPerMonth: -1, // Unlimited
      aiInsightsPerMonth: -1, // Unlimited
      riskPredictionsEnabled: true,
      inventoryForecastEnabled: true,
    );
  }
}
