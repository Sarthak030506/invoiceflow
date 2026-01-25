/// Model for inventory demand forecasting
class InventoryForecast {
  final String itemId;
  final String itemName;
  final String sku;
  final String category;
  final double currentStock;
  final double reorderPoint;
  final double dailyDemand;
  final double weeklyDemand;
  final int daysUntilStockout;
  final double recommendedOrderQty;
  final double safetyStock;
  final ForecastConfidence confidence;
  final ForecastAlert? alert;
  final TrendDirection trend;
  final double seasonalMultiplier;
  final DateTime forecastDate;
  final Map<String, dynamic>? metadata;
  final String? aiRecommendation; // AI-generated recommendation

  InventoryForecast({
    required this.itemId,
    required this.itemName,
    required this.sku,
    required this.category,
    required this.currentStock,
    required this.reorderPoint,
    required this.dailyDemand,
    this.weeklyDemand = 0,
    this.daysUntilStockout = 0,
    this.recommendedOrderQty = 0,
    this.safetyStock = 0,
    this.confidence = ForecastConfidence.medium,
    this.alert,
    this.trend = TrendDirection.stable,
    this.seasonalMultiplier = 1.0,
    DateTime? forecastDate,
    this.metadata,
    this.aiRecommendation,
  }) : forecastDate = forecastDate ?? DateTime.now();

  bool get needsReorder => currentStock <= reorderPoint;
  bool get isCritical => daysUntilStockout <= 3 && daysUntilStockout >= 0;
  bool get isOverstocked => daysUntilStockout > 60;

  factory InventoryForecast.fromMap(Map<String, dynamic> map) {
    return InventoryForecast(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      sku: map['sku'] ?? '',
      category: map['category'] ?? '',
      currentStock: (map['currentStock'] ?? 0).toDouble(),
      reorderPoint: (map['reorderPoint'] ?? 0).toDouble(),
      dailyDemand: (map['dailyDemand'] ?? 0).toDouble(),
      weeklyDemand: (map['weeklyDemand'] ?? 0).toDouble(),
      daysUntilStockout: map['daysUntilStockout'] ?? 0,
      recommendedOrderQty: (map['recommendedOrderQty'] ?? 0).toDouble(),
      safetyStock: (map['safetyStock'] ?? 0).toDouble(),
      confidence: ForecastConfidence.values.firstWhere(
        (e) => e.name == map['confidence'],
        orElse: () => ForecastConfidence.medium,
      ),
      alert: map['alert'] != null ? ForecastAlert.fromMap(map['alert']) : null,
      trend: TrendDirection.values.firstWhere(
        (e) => e.name == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      seasonalMultiplier: (map['seasonalMultiplier'] ?? 1.0).toDouble(),
      forecastDate: map['forecastDate'] != null
          ? DateTime.parse(map['forecastDate'])
          : DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'sku': sku,
      'category': category,
      'currentStock': currentStock,
      'reorderPoint': reorderPoint,
      'dailyDemand': dailyDemand,
      'weeklyDemand': weeklyDemand,
      'daysUntilStockout': daysUntilStockout,
      'recommendedOrderQty': recommendedOrderQty,
      'safetyStock': safetyStock,
      'confidence': confidence.name,
      'alert': alert?.toMap(),
      'trend': trend.name,
      'seasonalMultiplier': seasonalMultiplier,
      'forecastDate': forecastDate.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum ForecastConfidence {
  high,   // Lots of historical data, consistent patterns
  medium, // Some data, reasonable predictions
  low,    // Limited data, rough estimates
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

class ForecastAlert {
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final String? actionText;

  ForecastAlert({
    required this.type,
    required this.message,
    required this.severity,
    this.actionText,
  });

  factory ForecastAlert.fromMap(Map<String, dynamic> map) {
    return ForecastAlert(
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.info,
      ),
      message: map['message'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      actionText: map['actionText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'severity': severity.name,
      'actionText': actionText,
    };
  }
}

enum AlertType {
  stockout,      // Will run out of stock soon
  overstock,     // Too much stock
  slowMoving,    // No sales in a while
  seasonalSpike, // Seasonal demand increase expected
  reorderNow,    // Below reorder point
  info,          // General information
}

enum AlertSeverity {
  critical,
  warning,
  info,
}

/// Summary report for inventory forecasting
class InventoryForecastReport {
  final List<InventoryForecast> forecasts;
  final int totalItems;
  final int needsReorderCount;
  final int criticalCount;
  final int overstockedCount;
  final int slowMovingCount;
  final double totalReorderValue;
  final DateTime generatedAt;
  final String? summary; // AI-generated summary
  final bool isAIPowered; // Whether this report was generated using AI

  InventoryForecastReport({
    required this.forecasts,
    DateTime? generatedAt,
    this.summary,
    this.isAIPowered = false,
  })  : totalItems = forecasts.length,
        needsReorderCount = forecasts.where((f) => f.needsReorder).length,
        criticalCount = forecasts.where((f) => f.isCritical).length,
        overstockedCount = forecasts.where((f) => f.isOverstocked).length,
        slowMovingCount = forecasts.where((f) => f.alert?.type == AlertType.slowMoving).length,
        totalReorderValue = forecasts
            .where((f) => f.needsReorder)
            .fold(0, (sum, f) => sum + f.recommendedOrderQty),
        generatedAt = generatedAt ?? DateTime.now();

  List<InventoryForecast> get criticalItems =>
      forecasts.where((f) => f.isCritical).toList();

  List<InventoryForecast> get needsReorderItems =>
      forecasts.where((f) => f.needsReorder).toList();

  List<InventoryForecast> get sortedByUrgency {
    final sorted = List<InventoryForecast>.from(forecasts);
    sorted.sort((a, b) => a.daysUntilStockout.compareTo(b.daysUntilStockout));
    return sorted;
  }
}
