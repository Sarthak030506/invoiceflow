import 'package:flutter/foundation.dart';
import 'package:invoiceflow/models/inventory_forecast_model.dart';
import 'package:invoiceflow/models/inventory_item_model.dart';
import 'package:invoiceflow/models/stock_movement_model.dart';
import 'package:invoiceflow/services/inventory_service.dart';

/// Service for forecasting inventory demand
class InventoryForecastService {
  static InventoryForecastService? _instance;
  InventoryForecastService._internal();

  static InventoryForecastService get instance {
    _instance ??= InventoryForecastService._internal();
    return _instance!;
  }

  final InventoryService _inventoryService = InventoryService();

  // Default lead time in days (time to receive stock after ordering)
  static const int _defaultLeadTime = 7;
  // Service level factor for 95% service level
  static const double _serviceLevelFactor = 1.65;

  /// Generate forecast report for all inventory items
  Future<InventoryForecastReport> generateForecastReport() async {
    try {
      final items = await _inventoryService.getAllItems();
      final forecasts = <InventoryForecast>[];

      for (final item in items) {
        final forecast = await generateItemForecast(item);
        if (forecast != null) {
          forecasts.add(forecast);
        }
      }

      // Sort by urgency (days until stockout)
      forecasts.sort((a, b) {
        // Critical items first
        if (a.isCritical && !b.isCritical) return -1;
        if (!a.isCritical && b.isCritical) return 1;
        // Then by needs reorder
        if (a.needsReorder && !b.needsReorder) return -1;
        if (!a.needsReorder && b.needsReorder) return 1;
        // Then by days until stockout
        return a.daysUntilStockout.compareTo(b.daysUntilStockout);
      });

      return InventoryForecastReport(forecasts: forecasts);
    } catch (e) {
      debugPrint('Error generating forecast report: $e');
      return InventoryForecastReport(forecasts: []);
    }
  }

  /// Generate forecast for a specific item
  Future<InventoryForecast?> generateItemForecast(InventoryItem item) async {
    try {
      // Get stock movements for the past 90 days
      final movements = await _inventoryService.getMovementsByItem(item.id);
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));

      // Filter to recent OUT movements (sales)
      final recentSales = movements.where((m) {
        return m.type == StockMovementType.OUT &&
            m.createdAt.isAfter(ninetyDaysAgo);
      }).toList();

      // Calculate demand metrics
      final demandData = _calculateDemand(recentSales, item);
      final dailyDemand = demandData['dailyDemand'] as double;
      final weeklyDemand = demandData['weeklyDemand'] as double;
      final demandVariability = demandData['variability'] as double;

      // Calculate safety stock
      final safetyStock = _calculateSafetyStock(
        demandVariability,
        _defaultLeadTime,
      );

      // Calculate days until stockout
      final daysUntilStockout = dailyDemand > 0
          ? (item.currentStock / dailyDemand).floor()
          : 999; // Effectively infinite if no demand

      // Calculate recommended order quantity
      final recommendedOrderQty = _calculateReorderQuantity(
        dailyDemand,
        item.reorderPoint,
        item.currentStock,
        safetyStock,
      );

      // Determine trend
      final trend = _calculateTrend(recentSales);

      // Determine confidence level
      final confidence = _determineConfidence(recentSales.length);

      // Generate alert if needed
      final alert = _generateAlert(
        item,
        daysUntilStockout,
        dailyDemand,
        recentSales.length,
      );

      // Calculate seasonal multiplier (simplified - based on current month)
      final seasonalMultiplier = _getSeasonalMultiplier(now.month);

      return InventoryForecast(
        itemId: item.id,
        itemName: item.name,
        sku: item.sku,
        category: item.category,
        currentStock: item.currentStock,
        reorderPoint: item.reorderPoint,
        dailyDemand: dailyDemand,
        weeklyDemand: weeklyDemand,
        daysUntilStockout: daysUntilStockout,
        recommendedOrderQty: recommendedOrderQty,
        safetyStock: safetyStock,
        confidence: confidence,
        alert: alert,
        trend: trend,
        seasonalMultiplier: seasonalMultiplier,
        metadata: {
          'movementsAnalyzed': recentSales.length,
          'demandVariability': demandVariability,
          'leadTime': _defaultLeadTime,
        },
      );
    } catch (e) {
      debugPrint('Error generating forecast for item ${item.id}: $e');
      return null;
    }
  }

  /// Calculate daily and weekly demand from movements
  Map<String, dynamic> _calculateDemand(
    List<StockMovement> salesMovements,
    InventoryItem item,
  ) {
    if (salesMovements.isEmpty) {
      return {
        'dailyDemand': 0.0,
        'weeklyDemand': 0.0,
        'variability': 0.0,
      };
    }

    // Group sales by week
    final weeklySales = <int, double>{};
    final now = DateTime.now();

    for (final movement in salesMovements) {
      final weeksAgo = now.difference(movement.createdAt).inDays ~/ 7;
      weeklySales[weeksAgo] = (weeklySales[weeksAgo] ?? 0) + movement.quantity;
    }

    // Calculate average weekly demand
    final totalWeeks = weeklySales.keys.isEmpty
        ? 1
        : (weeklySales.keys.reduce((a, b) => a > b ? a : b) + 1);
    final totalSold =
        salesMovements.fold<double>(0, (sum, m) => sum + m.quantity);
    final avgWeeklyDemand = totalSold / totalWeeks;
    final avgDailyDemand = avgWeeklyDemand / 7;

    // Calculate variability (standard deviation)
    double variability = 0;
    if (weeklySales.length > 1) {
      final mean = avgWeeklyDemand;
      double sumSquaredDiff = 0;
      for (final weekSales in weeklySales.values) {
        sumSquaredDiff += (weekSales - mean) * (weekSales - mean);
      }
      variability =
          (sumSquaredDiff / weeklySales.length).abs();
      variability = variability > 0 ? variability * 0.5 : 0; // sqrt approximation
    }

    return {
      'dailyDemand': avgDailyDemand,
      'weeklyDemand': avgWeeklyDemand,
      'variability': variability,
    };
  }

  /// Calculate safety stock
  double _calculateSafetyStock(double demandVariability, int leadTime) {
    // Safety Stock = Z * σ * √Lead Time
    // Z = 1.65 for 95% service level
    // σ = standard deviation of demand
    if (demandVariability == 0) return 0;

    final sqrtLeadTime = leadTime > 0 ? leadTime * 0.5 : 1; // sqrt approximation
    return _serviceLevelFactor * demandVariability * sqrtLeadTime;
  }

  /// Calculate recommended reorder quantity
  double _calculateReorderQuantity(
    double dailyDemand,
    double reorderPoint,
    double currentStock,
    double safetyStock,
  ) {
    if (dailyDemand == 0) return 0;

    // Economic Order Quantity simplified
    // Order enough for 30 days + safety stock
    final targetStock = (dailyDemand * 30) + safetyStock;
    final orderQty = targetStock - currentStock;

    return orderQty > 0 ? orderQty : 0;
  }

  /// Calculate demand trend
  TrendDirection _calculateTrend(List<StockMovement> movements) {
    if (movements.length < 4) return TrendDirection.stable;

    // Compare first half vs second half
    final midpoint = movements.length ~/ 2;
    final firstHalf = movements.sublist(0, midpoint);
    final secondHalf = movements.sublist(midpoint);

    final firstHalfTotal =
        firstHalf.fold<double>(0, (sum, m) => sum + m.quantity);
    final secondHalfTotal =
        secondHalf.fold<double>(0, (sum, m) => sum + m.quantity);

    final change = firstHalfTotal > 0
        ? ((secondHalfTotal - firstHalfTotal) / firstHalfTotal) * 100
        : 0;

    if (change > 20) return TrendDirection.increasing;
    if (change < -20) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  /// Determine forecast confidence based on data availability
  ForecastConfidence _determineConfidence(int movementCount) {
    if (movementCount >= 20) return ForecastConfidence.high;
    if (movementCount >= 5) return ForecastConfidence.medium;
    return ForecastConfidence.low;
  }

  /// Generate alert for item if needed
  ForecastAlert? _generateAlert(
    InventoryItem item,
    int daysUntilStockout,
    double dailyDemand,
    int movementCount,
  ) {
    // Critical stockout alert
    if (daysUntilStockout <= 3 && daysUntilStockout >= 0 && dailyDemand > 0) {
      return ForecastAlert(
        type: AlertType.stockout,
        message:
            'Will run out in $daysUntilStockout days! Order now.',
        severity: AlertSeverity.critical,
        actionText: 'Order Now',
      );
    }

    // Reorder point alert
    if (item.currentStock <= item.reorderPoint && dailyDemand > 0) {
      return ForecastAlert(
        type: AlertType.reorderNow,
        message: 'Below reorder point. Time to restock.',
        severity: AlertSeverity.warning,
        actionText: 'Reorder',
      );
    }

    // Overstock alert
    if (daysUntilStockout > 60 && dailyDemand > 0) {
      return ForecastAlert(
        type: AlertType.overstock,
        message:
            '${daysUntilStockout}+ days of stock. Consider reducing order.',
        severity: AlertSeverity.info,
        actionText: 'Review',
      );
    }

    // Slow moving alert
    if (movementCount == 0 && item.currentStock > 0) {
      return ForecastAlert(
        type: AlertType.slowMoving,
        message: 'No sales in 90 days. Consider discounting.',
        severity: AlertSeverity.warning,
        actionText: 'Review',
      );
    }

    return null;
  }

  /// Get seasonal multiplier based on month
  /// This is a simplified version - in production, would use historical data
  double _getSeasonalMultiplier(int month) {
    // Indian festive seasons have higher demand
    switch (month) {
      case 10: // October - Diwali season
      case 11: // November - Wedding season
        return 1.5;
      case 8: // August - Raksha Bandhan
      case 9: // September - Navratri
        return 1.3;
      case 12: // December - Year end
      case 1: // January - New year
        return 1.2;
      case 5: // May - Summer
      case 6: // June - Summer
        return 0.9;
      default:
        return 1.0;
    }
  }

  /// Get items that need immediate reorder
  Future<List<InventoryForecast>> getCriticalItems() async {
    final report = await generateForecastReport();
    return report.criticalItems;
  }

  /// Get all items that need reorder
  Future<List<InventoryForecast>> getReorderList() async {
    final report = await generateForecastReport();
    return report.needsReorderItems;
  }

  /// Get forecast summary statistics
  Future<Map<String, dynamic>> getForecastSummary() async {
    final report = await generateForecastReport();

    return {
      'totalItems': report.totalItems,
      'criticalCount': report.criticalCount,
      'needsReorderCount': report.needsReorderCount,
      'overstockedCount': report.overstockedCount,
      'slowMovingCount': report.slowMovingCount,
      'generatedAt': report.generatedAt.toIso8601String(),
    };
  }
}
