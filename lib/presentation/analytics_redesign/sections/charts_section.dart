import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';

class ChartsSection extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic> chartData;
  final Map<String, dynamic> inventoryAnalytics;

  const ChartsSection({
    Key? key,
    required this.isLoading,
    required this.chartData,
    required this.inventoryAnalytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SkeletonLoader.chart(height: 250),
                const SizedBox(height: 16),
                SkeletonLoader.chart(height: 250),
                const SizedBox(height: 16),
                SkeletonLoader.chart(height: 200),
                const SizedBox(height: 16),
                SkeletonLoader.chart(height: 200),
              ],
            ),
          )
        : Column(
            children: [
              _buildRevenueChart(),
              const SizedBox(height: 16),
              _buildSalesVsPurchasesChart(),
              const SizedBox(height: 16),
              _buildTopItemsChart(),
              const SizedBox(height: 16),
              _buildInventoryChart(),
            ],
          );
  }

  Widget _buildRevenueChart() {
    final revenueTrend = chartData['revenueTrend'] as List<dynamic>? ?? [];
    final maxRevenue = revenueTrend.isEmpty ? 1000.0 : revenueTrend.map((e) => e['revenue'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Revenue Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: revenueTrend.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: revenueTrend.take(7).map((item) {
                      final revenue = item['revenue'] as double;
                      final height = (revenue / maxRevenue) * 160;
                      final date = DateTime.parse(item['date']);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesVsPurchasesChart() {
    final salesVsPurchases = chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    final sales = salesVsPurchases['sales'] as double? ?? 0.0;
    final purchases = salesVsPurchases['purchases'] as double? ?? 0.0;
    final total = sales + purchases;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sales vs Purchases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          if (total > 0)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  startAngle: 0,
                                  endAngle: (sales / total) * 6.28,
                                  colors: [Colors.blue, Colors.blue],
                                  stops: [0.0, 1.0],
                                ),
                              ),
                            ),
                          Center(
                            child: Text(
                              _formatCurrency(total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Sales', sales, Colors.blue),
                    const SizedBox(height: 12),
                    _buildLegendItem('Purchases', purchases, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsChart() {
    final topItems = (chartData['topSellingItems'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().take(5).toList();
    final maxRevenue = topItems.isEmpty ? 1000.0 : topItems.map((e) => e['revenue'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Top Selling Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topItems.map((item) {
            final revenue = item['revenue'] as double;
            final barWidth = maxRevenue > 0 ? (revenue / maxRevenue) * 200 : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['itemName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatCurrency(revenue),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 6,
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInventoryChart() {
    final totalItems = inventoryAnalytics['totalItems'] ?? 0;
    final lowStockCount = inventoryAnalytics['lowStockCount'] ?? 0;
    final healthyStock = totalItems - lowStockCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Inventory Health',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInventoryMetric(
                  'Healthy Stock',
                  healthyStock.toString(),
                  Colors.green,
                  totalItems > 0 ? healthyStock / totalItems : 0.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryMetric(
                  'Low Stock',
                  lowStockCount.toString(),
                  Colors.red,
                  totalItems > 0 ? lowStockCount / totalItems : 0.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatCurrency(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryMetric(String label, String value, Color color, double percentage) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    startAngle: 0,
                    endAngle: percentage * 6.28,
                    colors: [color, color],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
