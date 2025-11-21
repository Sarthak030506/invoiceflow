import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/sparkline_painter.dart';
import '../../../services/analytics_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/inventory_service.dart';
import '../item_wise_revenue_screen.dart';
import '../customer_wise_revenue_screen.dart';

class RevenueAnalyticsSection extends StatefulWidget {
  final bool isLoading;
  final String selectedDateRange;  final Map<String, dynamic> chartData;
  final List<Map<String, dynamic>> customerAnalyticsData;
  final Map<String, dynamic> inventoryAnalytics;

  const RevenueAnalyticsSection({
    Key? key,
    required this.isLoading,
    required this.selectedDateRange,
    required this.chartData,
    required this.customerAnalyticsData,
    required this.inventoryAnalytics,
  }) : super(key: key);

  @override
  State<RevenueAnalyticsSection> createState() => _RevenueAnalyticsSectionState();
}

class _RevenueAnalyticsSectionState extends State<RevenueAnalyticsSection> {
  bool _isCustomerWiseView = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('revenueSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          widget.isLoading
              ? Column(
                  children: [
                    SkeletonLoader.kpiCard(icon: Icons.attach_money, color: Colors.green),
                    SizedBox(height: 12),
                    SkeletonLoader.kpiCard(icon: Icons.bar_chart, color: Colors.blue),
                  ],
                )
              : Column(
                  children: [
                    _buildTodaysRevenueCard(),
                    SizedBox(height: 12),
                    _buildItemRevenueCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTodaysRevenueCard() {
    final periodRevenue = _getPeriodRevenue();
    final periodLabel = _getRevenueCardLabel();
    final comparisonLabel = _getComparisonLabel();

    return Container(
      key: const Key('revenueTodayCard'),
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
              Icon(Icons.attach_money, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  periodLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildMiniSparkline(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(periodRevenue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comparisonLabel,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRevenueCard() {
    final topItems = _isCustomerWiseView ? [] : _getTopSellingItems();
    final topCustomers = _isCustomerWiseView ? _getTopCustomers() : [];

    return Container(
      key: const Key('itemRevenueCard'),
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
              Icon(
                _isCustomerWiseView ? Icons.people : Icons.bar_chart,
                color: _isCustomerWiseView ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCustomerWiseView
                      ? 'Customer-wise Revenue Breakdown'
                      : 'Item-wise Revenue Breakdown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isCustomerWiseView
                    ? _showFullCustomerBreakdown
                    : _showFullItemBreakdown,
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Toggle between Item Wise and Customer Wise
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomerWiseView = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isCustomerWiseView
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Item Wise',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: !_isCustomerWiseView
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomerWiseView = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isCustomerWiseView
                            ? Colors.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Customer Wise',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isCustomerWiseView
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isCustomerWiseView)
            ...topItems.take(5).map((item) => _buildHorizontalBar(item)),
          if (_isCustomerWiseView)
            ...topCustomers
                .take(5)
                .map((customer) => _buildCustomerHorizontalBar(customer)),
        ],
      ),
    );
  }

  Widget _buildMiniSparkline() {
    return Container(
      width: 60,
      height: 20,
      child: CustomPaint(
        painter: SparklinePainter(_getLast7DaysData()),
      ),
    );
  }

  Widget _buildHorizontalBar(Map<String, dynamic> item) {
    final itemName = item['itemName'] as String? ?? 'Unknown';
    final revenue = (item['revenue'] as double?) ?? 0.0;
    final maxRevenue = _getMaxItemRevenue();
    final barWidth = maxRevenue > 0 ? (revenue / maxRevenue) * 200 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemName,
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
                  color: Colors.blue,
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
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHorizontalBar(Map<String, dynamic> customer) {
    final customerName = customer['customerName'] as String? ?? 'Unknown';
    final revenue = (customer['totalRevenue'] as double?) ?? 0.0;
    final invoiceCount = (customer['invoiceCount'] as int?) ?? 0;
    final maxRevenue = _getMaxCustomerRevenue();
    final barWidth = maxRevenue > 0 ? (revenue / maxRevenue) * 200 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$invoiceCount invoice${invoiceCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(revenue),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
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
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingBucket(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  double _getPeriodRevenue() {
    final salesVsPurchases = widget.chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    final salesRevenue = (salesVsPurchases['sales'] as double?) ?? 0.0;
    return salesRevenue;
  }

  String _getRevenueCardLabel() {
    switch (widget.selectedDateRange) {
      case 'today':
        return "Today's Revenue";
      case 'last7':
        return 'Last 7 Days Revenue';
      case 'last30':
        return 'Last 30 Days Revenue';
      case 'last90':
        return 'Last 3 Months Revenue';
      case 'custom':
        return 'Custom Period Revenue';
      default:
        return 'Total Revenue';
    }
  }

  String _getComparisonLabel() {
    final revenueTrend = widget.chartData['revenueTrend'] as List<dynamic>? ?? [];
    final invoiceTypeBreakdown = widget.chartData['invoiceTypeBreakdown'] as Map<String, dynamic>?;

    if (invoiceTypeBreakdown != null) {
      final salesCount = invoiceTypeBreakdown['salesCount'] as int? ?? 0;
      final purchaseCount = invoiceTypeBreakdown['purchaseCount'] as int? ?? 0;
      return '$salesCount sales, $purchaseCount purchases';
    }

    return '${revenueTrend.length} transaction days';
  }

  List<Map<String, dynamic>> _getTopSellingItems() {
    final topItems = widget.chartData['topSellingItems'] as List<dynamic>? ?? [];
    return topItems.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _getTopCustomers() {
    return widget.customerAnalyticsData;
  }

  double _getMaxItemRevenue() {
    final items = _getTopSellingItems();
    if (items.isEmpty) return 1000.0;
    return items.map((e) => (e['revenue'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);
  }

  double _getMaxCustomerRevenue() {
    final customers = _getTopCustomers();
    if (customers.isEmpty) return 1000.0;
    return customers.map((e) => (e['totalRevenue'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);
  }

  List<double> _getLast7DaysData() {
    final revenueTrend = widget.chartData['revenueTrend'] as List<dynamic>? ?? [];
    if (revenueTrend.isEmpty) return [0, 0, 0, 0, 0, 0, 0];

    final last7Days = revenueTrend.take(7).map((item) =>
      (item['revenue'] as double?) ?? 0.0
    ).toList();

    while (last7Days.length < 7) {
      last7Days.insert(0, 0.0);
    }

    return last7Days;
  }

  void _showFullItemBreakdown() {
    String dateRangeLabel = _getDateRangeLabel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemWiseRevenueScreen(
          items: _getTopSellingItems(),
          dateRange: dateRangeLabel,
        ),
      ),
    );
  }

  void _showFullCustomerBreakdown() {
    String dateRangeLabel = _getDateRangeLabel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerWiseRevenueScreen(
          customers: _getTopCustomers(),
          dateRange: dateRangeLabel,
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    switch (widget.selectedDateRange) {
      case 'today':
        return 'Today';
      case 'last7':
        return 'Last 7 Days';
      case 'last30':
        return 'Last 30 Days';
      case 'last90':
        return 'Last 3 Months';
      case 'custom':
        return 'Custom Range';
      default:
        return 'All Time';
    }
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


