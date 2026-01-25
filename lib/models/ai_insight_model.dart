/// Model for AI-generated business insights
class AIInsight {
  final String id;
  final InsightType type;
  final InsightCategory category;
  final String title;
  final String description;
  final String? actionText;
  final double? value;
  final double? changePercent;
  final bool isPositive;
  final InsightPriority priority;
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;

  AIInsight({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.actionText,
    this.value,
    this.changePercent,
    this.isPositive = true,
    this.priority = InsightPriority.medium,
    DateTime? generatedAt,
    this.metadata,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    return AIInsight(
      id: map['id'] ?? '',
      type: InsightType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InsightType.general,
      ),
      category: InsightCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => InsightCategory.revenue,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      actionText: map['actionText'],
      value: map['value']?.toDouble(),
      changePercent: map['changePercent']?.toDouble(),
      isPositive: map['isPositive'] ?? true,
      priority: InsightPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => InsightPriority.medium,
      ),
      generatedAt: map['generatedAt'] != null
          ? DateTime.parse(map['generatedAt'])
          : DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'title': title,
      'description': description,
      'actionText': actionText,
      'value': value,
      'changePercent': changePercent,
      'isPositive': isPositive,
      'priority': priority.name,
      'generatedAt': generatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum InsightType {
  trend,       // Revenue/sales trends
  alert,       // Warnings or issues
  opportunity, // Growth opportunities
  milestone,   // Achievement notifications
  recommendation, // Actionable suggestions
  general,     // General insights
}

enum InsightCategory {
  revenue,
  products,
  customers,
  inventory,
  payments,
  growth,
}

enum InsightPriority {
  high,
  medium,
  low,
}

/// Collection of insights with summary
class BusinessInsightsReport {
  final List<AIInsight> insights;
  final DateTime generatedAt;
  final int totalInsights;
  final int highPriorityCount;
  final Map<InsightCategory, int> categoryBreakdown;

  BusinessInsightsReport({
    required this.insights,
    DateTime? generatedAt,
  })  : generatedAt = generatedAt ?? DateTime.now(),
        totalInsights = insights.length,
        highPriorityCount = insights.where((i) => i.priority == InsightPriority.high).length,
        categoryBreakdown = _calculateCategoryBreakdown(insights);

  static Map<InsightCategory, int> _calculateCategoryBreakdown(List<AIInsight> insights) {
    final breakdown = <InsightCategory, int>{};
    for (final insight in insights) {
      breakdown[insight.category] = (breakdown[insight.category] ?? 0) + 1;
    }
    return breakdown;
  }
}
