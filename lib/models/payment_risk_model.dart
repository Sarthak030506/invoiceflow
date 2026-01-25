/// Model for payment risk prediction
class PaymentRiskScore {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double riskScore; // 0-100, higher = more risky
  final RiskLevel riskLevel;
  final double totalOutstanding;
  final int overdueInvoices;
  final int maxDaysOverdue;
  final double avgPaymentDelay; // Average days late for past payments
  final int totalInvoices;
  final int onTimePayments;
  final List<RiskFactor> riskFactors;
  final String? recommendedAction;
  final DateTime calculatedAt;
  final int? aiPredictedDays; // AI-predicted days until payment

  PaymentRiskScore({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.riskScore,
    required this.totalOutstanding,
    this.overdueInvoices = 0,
    this.maxDaysOverdue = 0,
    this.avgPaymentDelay = 0,
    this.totalInvoices = 0,
    this.onTimePayments = 0,
    List<RiskFactor>? riskFactors,
    this.recommendedAction,
    DateTime? calculatedAt,
    this.aiPredictedDays,
  })  : riskLevel = _calculateRiskLevel(riskScore),
        riskFactors = riskFactors ?? [],
        calculatedAt = calculatedAt ?? DateTime.now();

  static RiskLevel _calculateRiskLevel(double score) {
    if (score >= 80) return RiskLevel.critical;
    if (score >= 60) return RiskLevel.high;
    if (score >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  double get paymentReliability {
    if (totalInvoices == 0) return 100;
    return (onTimePayments / totalInvoices) * 100;
  }

  factory PaymentRiskScore.fromMap(Map<String, dynamic> map) {
    return PaymentRiskScore(
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      riskScore: (map['riskScore'] ?? 0).toDouble(),
      totalOutstanding: (map['totalOutstanding'] ?? 0).toDouble(),
      overdueInvoices: map['overdueInvoices'] ?? 0,
      maxDaysOverdue: map['maxDaysOverdue'] ?? 0,
      avgPaymentDelay: (map['avgPaymentDelay'] ?? 0).toDouble(),
      totalInvoices: map['totalInvoices'] ?? 0,
      onTimePayments: map['onTimePayments'] ?? 0,
      riskFactors: (map['riskFactors'] as List<dynamic>?)
              ?.map((f) => RiskFactor.fromMap(f))
              .toList() ??
          [],
      recommendedAction: map['recommendedAction'],
      calculatedAt: map['calculatedAt'] != null
          ? DateTime.parse(map['calculatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'totalOutstanding': totalOutstanding,
      'overdueInvoices': overdueInvoices,
      'maxDaysOverdue': maxDaysOverdue,
      'avgPaymentDelay': avgPaymentDelay,
      'totalInvoices': totalInvoices,
      'onTimePayments': onTimePayments,
      'riskFactors': riskFactors.map((f) => f.toMap()).toList(),
      'recommendedAction': recommendedAction,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

enum RiskLevel {
  critical, // 80-100: Immediate action needed
  high,     // 60-79: Follow up within 2-3 days
  medium,   // 40-59: Weekly reminder
  low,      // 0-39: Standard collection cycle
}

class RiskFactor {
  final String name;
  final String description;
  final double impact; // Contribution to risk score (0-100)
  final RiskFactorType type;

  RiskFactor({
    required this.name,
    required this.description,
    required this.impact,
    required this.type,
  });

  factory RiskFactor.fromMap(Map<String, dynamic> map) {
    return RiskFactor(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      impact: (map['impact'] ?? 0).toDouble(),
      type: RiskFactorType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RiskFactorType.other,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'impact': impact,
      'type': type.name,
    };
  }
}

enum RiskFactorType {
  daysOverdue,
  paymentHistory,
  creditRatio,
  invoiceSize,
  frequency,
  other,
}

/// Summary data for payment risk analysis
class PaymentRiskSummary {
  final double totalAtRisk;
  final int criticalCount;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final String? recommendation;

  PaymentRiskSummary({
    required this.totalAtRisk,
    required this.criticalCount,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    this.recommendation,
  });
}

/// Summary report for payment risk analysis
class PaymentRiskReport {
  final List<PaymentRiskScore> customerRisks;
  final PaymentRiskSummary summary;
  final DateTime generatedAt;
  final bool isAIPowered;

  PaymentRiskReport({
    required this.customerRisks,
    required this.summary,
    DateTime? generatedAt,
    this.isAIPowered = false,
  })  : generatedAt = generatedAt ?? DateTime.now();

  // Convenience getters from summary
  double get totalAtRisk => summary.totalAtRisk;
  int get criticalCount => summary.criticalCount;
  int get highRiskCount => summary.highRiskCount;
  int get mediumRiskCount => summary.mediumRiskCount;
  int get lowRiskCount => summary.lowRiskCount;

  List<PaymentRiskScore> get sortedByRisk {
    final sorted = List<PaymentRiskScore>.from(customerRisks);
    sorted.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return sorted;
  }

  List<PaymentRiskScore> get criticalCustomers =>
      customerRisks.where((c) => c.riskLevel == RiskLevel.critical).toList();
}
