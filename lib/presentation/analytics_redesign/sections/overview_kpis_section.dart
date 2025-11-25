import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';

class OverviewKpisSection extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic> chartData;
  final Map<String, dynamic> performanceInsights;
  final Function(String)? onSectionTap;

  const OverviewKpisSection({
    Key? key,
    required this.isLoading,
    required this.chartData,
    required this.performanceInsights,
    this.onSectionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('quickKpisSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          isLoading
              ? Container(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        width: 140,
                        child: SkeletonLoader.kpiCard(icon: Icons.trending_up, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 140,
                        child: SkeletonLoader.kpiCard(icon: Icons.shopping_cart, color: Colors.green),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 140,
                        child: SkeletonLoader.kpiCard(icon: Icons.account_balance_wallet, color: Colors.orange),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 140,
                        child: SkeletonLoader.kpiCard(icon: Icons.people, color: Colors.purple),
                      ),
                      SizedBox(width: 16),
                    ],
                  ),
                )
              : Container(
                  key: const Key('compactKpiCards'),
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildKpiCard(
                        title: 'Total Revenue',
                        value: _formatCurrency(_getTotalRevenue()),
                        delta: _getRevenueDelta(),
                        icon: Icons.trending_up,
                        onTap: () => onSectionTap?.call('revenue'),
                      ),
                      SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'Total Purchases',
                        value: _formatCurrency(_getTotalPurchases()),
                        icon: Icons.shopping_cart,
                        onTap: () => onSectionTap?.call('revenue'),
                      ),
                      SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'Outstanding',
                        value: _formatCurrency(_getOutstanding()),
                        icon: Icons.account_balance_wallet,
                        color: Colors.orange,
                        onTap: () => onSectionTap?.call('due'),
                      ),
                      SizedBox(width: 12),
                      _buildKpiCard(
                        title: 'Total Clients',
                        value: _getTotalClients().toString(),
                        icon: Icons.people,
                        color: Colors.purple,
                        onTap: () => onSectionTap?.call('items'),
                      ),
                      SizedBox(width: 16), // Extra padding at end
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    double? delta,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    final cardColor = color ?? Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                Icon(
                  icon,
                  size: 16,
                  color: cardColor,
                ),
                const Spacer(),
                if (delta != null) _buildDeltaBadge(delta),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaBadge(double delta) {
    final isPositive = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // Data extraction methods
  double _getTotalRevenue() {
    final salesVsPurchases = chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    return (salesVsPurchases['sales'] as double?) ?? 0.0;
  }

  double _getTotalPurchases() {
    final salesVsPurchases = chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    return (salesVsPurchases['purchases'] as double?) ?? 0.0;
  }

  double _getOutstanding() {
    final outstandingPayments = chartData['outstandingPayments'] as Map<String, dynamic>? ?? {};
    return (outstandingPayments['remaining'] as double?) ?? 0.0;
  }

  int _getTotalClients() {
    final insights = performanceInsights['insights'] as Map<String, dynamic>? ?? {};
    return (insights['totalClients'] as int?) ?? 0;
  }

  double? _getRevenueDelta() {
    final trends = performanceInsights['trends'] as Map<String, dynamic>? ?? {};
    return trends['revenueChange'] as double?;
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
