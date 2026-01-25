import 'package:flutter/material.dart';
import 'package:invoiceflow/models/inventory_forecast_model.dart';
import 'package:invoiceflow/services/ai/inventory_forecast_service.dart';

class InventoryForecastTab extends StatefulWidget {
  const InventoryForecastTab({super.key});

  @override
  State<InventoryForecastTab> createState() => _InventoryForecastTabState();
}

class _InventoryForecastTabState extends State<InventoryForecastTab> {
  bool _isLoading = true;
  InventoryForecastReport? _report;
  String? _error;
  String _filter = 'all'; // all, critical, reorder, overstock, slow

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report =
          await InventoryForecastService.instance.generateForecastReport();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load forecast data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing inventory trends...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadForecastData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_report == null || _report!.forecasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No inventory data available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add inventory items to see forecasts',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadForecastData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          ..._getFilteredForecasts().map((forecast) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildForecastCard(forecast),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Health',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  '${_report!.criticalCount}',
                  'Critical',
                  Icons.error,
                  Colors.red,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  '${_report!.needsReorderCount}',
                  'Need Reorder',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  '${_report!.overstockedCount}',
                  'Overstocked',
                  Icons.inventory,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  '${_report!.slowMovingCount}',
                  'Slow Moving',
                  Icons.speed,
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('Critical', 'critical', Icons.error),
          const SizedBox(width: 8),
          _buildFilterChip('Reorder', 'reorder', Icons.shopping_cart),
          const SizedBox(width: 8),
          _buildFilterChip('Overstock', 'overstock', Icons.inventory),
          const SizedBox(width: 8),
          _buildFilterChip('Slow', 'slow', Icons.speed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, IconData icon) {
    final isSelected = _filter == filter;

    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = filter;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  List<InventoryForecast> _getFilteredForecasts() {
    switch (_filter) {
      case 'critical':
        return _report!.forecasts.where((f) => f.isCritical).toList();
      case 'reorder':
        return _report!.forecasts.where((f) => f.needsReorder).toList();
      case 'overstock':
        return _report!.forecasts.where((f) => f.isOverstocked).toList();
      case 'slow':
        return _report!.forecasts
            .where((f) => f.alert?.type == AlertType.slowMoving)
            .toList();
      default:
        return _report!.sortedByUrgency;
    }
  }

  Widget _buildForecastCard(InventoryForecast forecast) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStockIndicator(forecast),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'SKU: ${forecast.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrendIndicator(forecast.trend),
              ],
            ),
            const SizedBox(height: 16),
            // Stock metrics
            Row(
              children: [
                _buildMetricItem(
                  'Current',
                  '${forecast.currentStock.toStringAsFixed(0)}',
                  Colors.blue,
                ),
                _buildMetricItem(
                  'Daily Demand',
                  forecast.dailyDemand.toStringAsFixed(1),
                  Colors.purple,
                ),
                _buildMetricItem(
                  'Days Left',
                  '${forecast.daysUntilStockout}',
                  _getDaysLeftColor(forecast.daysUntilStockout),
                ),
                _buildMetricItem(
                  'Reorder Qty',
                  forecast.recommendedOrderQty.toStringAsFixed(0),
                  Colors.green,
                ),
              ],
            ),
            if (forecast.alert != null) ...[
              const SizedBox(height: 12),
              _buildAlertBanner(forecast.alert!),
            ],
            const SizedBox(height: 12),
            // Confidence indicator
            Row(
              children: [
                const Text(
                  'Forecast Confidence: ',
                  style: TextStyle(fontSize: 12),
                ),
                _buildConfidenceBadge(forecast.confidence),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewItemDetails(forecast.itemId),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(InventoryForecast forecast) {
    Color color;
    IconData icon;

    if (forecast.isCritical) {
      color = Colors.red;
      icon = Icons.error;
    } else if (forecast.needsReorder) {
      color = Colors.orange;
      icon = Icons.warning;
    } else if (forecast.isOverstocked) {
      color = Colors.blue;
      icon = Icons.inventory;
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildTrendIndicator(TrendDirection trend) {
    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case TrendDirection.increasing:
        icon = Icons.trending_up;
        color = Colors.green;
        label = 'Rising';
        break;
      case TrendDirection.decreasing:
        icon = Icons.trending_down;
        color = Colors.red;
        label = 'Falling';
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = Colors.grey;
        label = 'Stable';
        break;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Color _getDaysLeftColor(int days) {
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    if (days <= 14) return Colors.amber.shade700;
    return Colors.green;
  }

  Widget _buildAlertBanner(ForecastAlert alert) {
    Color color;
    switch (alert.severity) {
      case AlertSeverity.critical:
        color = Colors.red;
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        break;
      case AlertSeverity.info:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getAlertIcon(alert.type), size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          if (alert.actionText != null)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(alert.actionText!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.stockout:
        return Icons.error;
      case AlertType.overstock:
        return Icons.inventory;
      case AlertType.slowMoving:
        return Icons.speed;
      case AlertType.seasonalSpike:
        return Icons.trending_up;
      case AlertType.reorderNow:
        return Icons.shopping_cart;
      case AlertType.info:
        return Icons.info;
    }
  }

  Widget _buildConfidenceBadge(ForecastConfidence confidence) {
    Color color;
    String label;

    switch (confidence) {
      case ForecastConfidence.high:
        color = Colors.green;
        label = 'High';
        break;
      case ForecastConfidence.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case ForecastConfidence.low:
        color = Colors.grey;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _viewItemDetails(String itemId) {
    Navigator.pushNamed(context, '/inventory/item/$itemId');
  }
}
