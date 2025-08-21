import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../analytics_screen/widgets/analytics_charts_widget.dart';

class ChartsInsightsSection extends StatelessWidget {
  final Map<String, dynamic> chartData;
  final Map<String, dynamic> performanceInsights;
  final Map<String, dynamic> inventoryAnalytics;

  const ChartsInsightsSection({
    Key? key,
    required this.chartData,
    required this.performanceInsights,
    required this.inventoryAnalytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          child: Text(
            'Charts & Insights',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
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
          child: AnalyticsChartsWidget(
            data: chartData,
            insights: performanceInsights,
          ),
        ),
        SizedBox(height: 3.w),
        if (performanceInsights.isNotEmpty) _buildKeyMetrics(context),
        if (performanceInsights['topRevenueItems'] != null) _buildTopItems(context),
      ],
    );
  }

  Widget _buildKeyMetrics(BuildContext context) {
    final insights = performanceInsights['insights'] as Map<String, dynamic>? ?? {};
    final trends = performanceInsights['trends'] as Map<String, dynamic>? ?? {};
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
      padding: EdgeInsets.all(4.w),
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
          Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Items',
                  insights['totalUniqueItems']?.toString() ?? '0',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Categories',
                  insights['totalCategories']?.toString() ?? '0',
                  Icons.category,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Clients',
                  insights['totalClients']?.toString() ?? '0',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Revenue Change',
                  '${(trends['revenueChange'] as double?)?.toStringAsFixed(1) ?? '0'}%',
                  Icons.trending_up,
                  (trends['revenueChange'] as double? ?? 0) >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems(BuildContext context) {
    final topItems = performanceInsights['topRevenueItems'] as List<dynamic>? ?? [];
    if (topItems.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
      padding: EdgeInsets.all(4.w),
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
          Text(
            'Top Revenue Items',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 3.w),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: topItems.length > 3 ? 3 : topItems.length,
            itemBuilder: (context, index) {
              final item = topItems[index] as Map<String, dynamic>;
              return Container(
                margin: EdgeInsets.only(bottom: 2.w),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 16,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['itemName'] as String,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Qty: ${item['quantitySold']}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(item['revenue'] as double).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 2.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}