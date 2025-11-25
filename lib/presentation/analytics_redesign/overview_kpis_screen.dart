import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/analytics_service.dart';
import '../../services/inventory_service.dart';
import '../../services/firestore_service.dart';
import './widgets/skeleton_loader.dart';

class OverviewKpisScreen extends StatefulWidget {
  final String selectedDateRange;
  final Map<String, DateTime>? customDateRange;

  const OverviewKpisScreen({
    Key? key,
    required this.selectedDateRange,
    this.customDateRange,
  }) : super(key: key);

  @override
  State<OverviewKpisScreen> createState() => _OverviewKpisScreenState();
}

class _OverviewKpisScreenState extends State<OverviewKpisScreen> {
  Map<String, dynamic> kpiData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKpiData();
  }

  Future<void> _loadKpiData() async {
    setState(() => _isLoading = true);
    
    try {
      final analyticsService = AnalyticsService();
      final inventoryService = InventoryService();
      final fs = FirestoreService.instance;
      
      String serviceRange = _mapDateRangeToService(widget.selectedDateRange);

      final results = await Future.wait([
        analyticsService.getChartAnalytics(serviceRange),
        analyticsService.fetchPerformanceInsights(serviceRange),
        inventoryService.getInventoryAnalytics(),
        fs.getAllInvoices(),
        fs.getAllCustomers(),
      ]);
      
      final chartData = results[0] as Map<String, dynamic>;
      final performanceInsights = results[1] as Map<String, dynamic>;
      final inventoryAnalytics = results[2] as Map<String, dynamic>;
      final allInvoices = results[3] as List<dynamic>;
      final allCustomers = results[4] as List<dynamic>;
      
      final salesVsPurchases = chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
      final outstandingPayments = chartData['outstandingPayments'] as Map<String, dynamic>? ?? {};
      final insights = performanceInsights['insights'] as Map<String, dynamic>? ?? {};
      final trends = performanceInsights['trends'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        kpiData = {
          'totalRevenue': {
            'value': salesVsPurchases['sales'] ?? 0.0,
            'change': trends['revenueChange'] ?? 0.0
          },
          'totalPurchases': {
            'value': salesVsPurchases['purchases'] ?? 0.0,
            'change': 0.0 // Purchase trend not available
          },
          'outstanding': {
            'value': outstandingPayments['remaining'] ?? 0.0,
            'change': 0.0 // Outstanding trend not available
          },
          'totalClients': {
            'value': allCustomers.length,
            'change': 0.0 // Client growth trend not available
          },
          'totalInvoices': {
            'value': allInvoices.length,
            'change': 0.0 // Invoice trend not available
          },
          'totalItems': {
            'value': inventoryAnalytics['totalItems'] ?? 0,
            'change': 0.0 // Item count trend not available
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        kpiData = {
          'totalRevenue': {'value': 0.0, 'change': 0.0},
          'totalPurchases': {'value': 0.0, 'change': 0.0},
          'outstanding': {'value': 0.0, 'change': 0.0},
          'totalClients': {'value': 0, 'change': 0.0},
          'totalInvoices': {'value': 0, 'change': 0.0},
          'totalItems': {'value': 0, 'change': 0.0},
        };
        _isLoading = false;
      });
    }
  }
  
  String _mapDateRangeToService(String dateRange) {
    switch (dateRange) {
      case 'last7':
        return 'Last 7 days';
      case 'last30':
        return 'Last 30 days';
      case 'last90':
        return 'Last 90 days';
      case 'custom':
        return 'Custom range';
      default:
        return 'All time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Overview KPIs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: _isLoading
          ? ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                SkeletonLoader.kpiCard(icon: Icons.trending_up, color: Colors.green),
                SizedBox(height: 3.w),
                SkeletonLoader.kpiCard(icon: Icons.shopping_cart, color: Colors.blue),
                SizedBox(height: 3.w),
                SkeletonLoader.kpiCard(icon: Icons.account_balance_wallet, color: Colors.orange),
                SizedBox(height: 3.w),
                SkeletonLoader.kpiCard(icon: Icons.people, color: Colors.purple),
                SizedBox(height: 3.w),
                SkeletonLoader.kpiCard(icon: Icons.receipt_long, color: Colors.indigo),
                SizedBox(height: 3.w),
                SkeletonLoader.kpiCard(icon: Icons.inventory_2, color: Colors.teal),
              ],
            )
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildKpiCard('Total Revenue', kpiData['totalRevenue'], '₹', Icons.trending_up, Colors.green),
                SizedBox(height: 3.w),
                _buildKpiCard('Total Purchases', kpiData['totalPurchases'], '₹', Icons.shopping_cart, Colors.blue),
                SizedBox(height: 3.w),
                _buildKpiCard('Outstanding', kpiData['outstanding'], '₹', Icons.account_balance_wallet, Colors.orange),
                SizedBox(height: 3.w),
                _buildKpiCard('Total Clients', kpiData['totalClients'], '', Icons.people, Colors.purple),
                SizedBox(height: 3.w),
                _buildKpiCard('Total Invoices', kpiData['totalInvoices'], '', Icons.receipt_long, Colors.indigo),
                SizedBox(height: 3.w),
                _buildKpiCard('Total Items', kpiData['totalItems'], '', Icons.inventory_2, Colors.teal),
              ],
            ),
    );
  }

  Widget _buildKpiCard(String title, Map<String, dynamic>? data, String prefix, IconData icon, Color color) {
    if (data == null) return SizedBox.shrink();
    
    final value = data['value'];
    final change = data['change'] as double;
    final isPositive = change >= 0;
    
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 6.w),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          Text(
            '$prefix${_formatValue(value)}',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.w),
          // Only show trend if there's actual change data
          if (change != 0.0)
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'vs ${_getPreviousPeriodText()}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )
          else
            Text(
              'No comparison data available',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      if (value >= 100000) {
        return '${(value / 100000).toStringAsFixed(1)}L';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    }
    return value.toString();
  }

  String _getDateRangeText() {
    switch (widget.selectedDateRange) {
      case 'last7':
        return 'Last 7 days';
      case 'last30':
        return 'Last 30 days';
      case 'last90':
        return 'Last 3 months';
      case 'custom':
        if (widget.customDateRange != null) {
          final start = widget.customDateRange!['start']!;
          final end = widget.customDateRange!['end']!;
          return '${start.day}/${start.month} - ${end.day}/${end.month}';
        }
        return 'Custom range';
      default:
        return 'Current period';
    }
  }

  String _getPreviousPeriodText() {
    switch (widget.selectedDateRange) {
      case 'last7':
        return 'previous 7 days';
      case 'last30':
        return 'previous 30 days';
      case 'last90':
        return 'previous 3 months';
      default:
        return 'previous period';
    }
  }

}