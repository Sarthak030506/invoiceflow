import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnalyticsChartsWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> insights;

  const AnalyticsChartsWidget({
    Key? key,
    required this.data,
    required this.insights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSimpleStatCard(context, 'Sales vs Purchases', _formatSalesVsPurchases()),
          SizedBox(height: 4.h),
          _buildSimpleStatCard(context, 'Revenue Overview', _formatRevenueTrendSummary()),
          SizedBox(height: 4.h),
          _buildSimpleStatCard(context, 'Top Selling Items', _formatTopItemsSummary()),
          SizedBox(height: 4.h),
          _buildSimpleStatCard(context, 'Outstanding Payments', _formatOutstandingPaymentsSummary()),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(BuildContext context, String title, String body) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 2.h),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSalesVsPurchases() {
    final m = data['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    final s = (m['sales'] as double?) ?? 0.0;
    final p = (m['purchases'] as double?) ?? 0.0;
    return 'Sales: ₹${s.toStringAsFixed(0)} • Purchases: ₹${p.toStringAsFixed(0)}';
  }

  String _formatRevenueTrendSummary() {
    final trend = (data['revenueTrend'] as List<dynamic>? ?? [])
        .map((e) => (e['revenue'] as double?) ?? 0.0)
        .toList();
    if (trend.isEmpty) return 'No data available';
    final max = trend.reduce((a, b) => a > b ? a : b);
    final avg = trend.reduce((a, b) => a + b) / trend.length;
    return 'Days: ${trend.length} • Max: ₹${max.toStringAsFixed(0)} • Avg: ₹${avg.toStringAsFixed(0)}';
  }

  String _formatTopItemsSummary() {
    final topItems = (data['topSellingItems'] as List<dynamic>? ?? []);
    if (topItems.isEmpty) return 'No data available';
    final names = topItems.take(5).map((e) => e['itemName'] as String? ?? 'Item').join(', ');
    return 'Top items: $names';
  }

  String _formatOutstandingPaymentsSummary() {
    final m = data['outstandingPayments'] as Map<String, dynamic>? ?? {};
    final paid = (m['paid'] as double?) ?? 0.0;
    final remaining = (m['remaining'] as double?) ?? 0.0;
    final total = paid + remaining;
    if (total == 0) return 'No payment data available';
    final paidPct = (paid / total * 100).toStringAsFixed(0);
    final remPct = (remaining / total * 100).toStringAsFixed(0);
    return 'Collected: ₹${paid.toStringAsFixed(0)} ($paidPct%) • Pending: ₹${remaining.toStringAsFixed(0)} ($remPct%)';
  }
}


