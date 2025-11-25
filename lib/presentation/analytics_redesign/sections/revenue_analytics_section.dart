import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/sparkline_painter.dart';
import '../../../services/analytics_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/inventory_service.dart';
import '../widgets/embedded_item_wise_revenue.dart';
import '../widgets/embedded_customer_wise_revenue.dart';

class RevenueAnalyticsSection extends StatefulWidget {
  final bool isLoading;
  final String selectedDateRange;
  final Map<String, dynamic> chartData;
  final List<Map<String, dynamic>> customerAnalyticsData;
  final Map<String, dynamic> inventoryAnalytics;
  final InventoryService? inventoryService;

  const RevenueAnalyticsSection({
    Key? key,
    required this.isLoading,
    required this.selectedDateRange,
    required this.chartData,
    required this.customerAnalyticsData,
    required this.inventoryAnalytics,
    this.inventoryService,
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
                    SizedBox(height: 24),
                    _buildBreakdownSection(),
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

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Icon(
              Icons.pie_chart,
              color: Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Custom Tab Selector
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCustomerWiseView = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isCustomerWiseView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_isCustomerWiseView
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      'Item Wise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !_isCustomerWiseView ? FontWeight.w600 : FontWeight.w500,
                        color: !_isCustomerWiseView ? Colors.blue.shade700 : Colors.grey.shade600,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCustomerWiseView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isCustomerWiseView
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      'Customer Wise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _isCustomerWiseView ? FontWeight.w600 : FontWeight.w500,
                        color: _isCustomerWiseView ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content Area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isCustomerWiseView
              ? EmbeddedCustomerWiseRevenue(
                  key: const ValueKey('customer_wise'),
                  customers: _getTopCustomers(),
                  dateRange: _getDateRangeLabel(),
                )
              : EmbeddedItemWiseRevenue(
                  key: const ValueKey('item_wise'),
                  items: _getTopSellingItems(),
                  dateRange: _getDateRangeLabel(),
                ),
        ),
      ],
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




