import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'widgets/sparkline_painter.dart';
import '../analytics_screen/widgets/analytics_table_widget.dart';
import '../../services/analytics_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/database_service.dart';

class AnalyticsRedesignScaffold extends StatefulWidget {
  final String? initialSection;
  final String? selectedDateRange;
  final Map<String, DateTime>? customDateRange;
  
  const AnalyticsRedesignScaffold({
    Key? key,
    this.initialSection,
    this.selectedDateRange,
    this.customDateRange,
  }) : super(key: key);

  @override
  State<AnalyticsRedesignScaffold> createState() => _AnalyticsRedesignScaffoldState();
}

class _AnalyticsRedesignScaffoldState extends State<AnalyticsRedesignScaffold> {
  late String selectedDateRange;
  Map<String, DateTime>? customDateRange;
  
  // Analytics data state
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> analyticsData = [];
  Map<String, dynamic> performanceInsights = {};
  Map<String, dynamic> chartData = {};
  Map<String, dynamic> inventoryAnalytics = {};
  Map<String, dynamic> outstandingPayments = {};
  
  // Table modal state
  String _searchQuery = '';
  String _sortColumn = 'revenue';
  bool _sortAscending = false;
  String _invoiceTypeFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    selectedDateRange = widget.selectedDateRange ?? 'last7';
    customDateRange = widget.customDateRange;
    refreshAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAnalyticsAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.initialSection == null) _buildDateChipsBar(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildSectionContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionContent() {
    if (widget.initialSection == null) {
      // Show all sections (original behavior)
      return Column(
        children: [
          SizedBox(height: 16),
          _buildQuickKpisSection(),
          SizedBox(height: 16),
          _buildRevenueSection(),
          SizedBox(height: 16),
          _buildItemsInsightsSection(),
          SizedBox(height: 16),
          _buildInventorySection(),
          SizedBox(height: 16),
          _buildDueRemindersSection(),
          SizedBox(height: 16),
          _buildAnalyticsTableCard(),
          SizedBox(height: 16),
        ],
      );
    }
    
    // Show specific section
    switch (widget.initialSection) {
      case 'overview':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildQuickKpisSection(),
        );
      case 'revenue':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildRevenueSection(),
        );
      case 'items':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildItemsInsightsSection(),
        );
      case 'inventory':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildInventorySection(),
        );
      case 'due':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildDueRemindersSection(),
        );
      case 'table':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildAnalyticsTableCard(),
        );
      case 'charts':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildChartsSection(),
        );
      default:
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildQuickKpisSection(),
        );
    }
  }
  
  Widget _buildChartsSection() {
    return Column(
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
    final topItems = _getTopSellingItems().take(5).toList();
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAnalyticsAppBar() {
    final sectionTitles = {
      'overview': 'Overview KPIs',
      'revenue': 'Revenue Analytics',
      'items': 'Items & Sales Insights',
      'inventory': 'Inventory Analytics',
      'due': 'Due Reminders',
      'table': 'Analytics Table',
      'charts': 'Charts',
    };
    
    return AppBar(
      key: const Key('analyticsAppBar'),
      title: Text(
        widget.initialSection != null 
            ? sectionTitles[widget.initialSection] ?? 'Analytics'
            : 'Analytics',
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
    );
  }

  Widget _buildDateChipsBar() {
    return Container(
      key: const Key('dateChipsBar'),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDateChip('Last 7 days', 'chip7d', 'last7'),
            SizedBox(width: 8),
            _buildDateChip('Last 30 days', 'chip30d', 'last30'),
            SizedBox(width: 8),
            _buildDateChip('Last 3 months', 'chip3m', 'last90'),
            SizedBox(width: 8),
            _buildCustomChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String chipId, String value) {
    final isSelected = selectedDateRange == value;
    return GestureDetector(
      key: Key(chipId),
      onTap: () => _onChipSelect(value),
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCustomChip() {
    final isSelected = selectedDateRange == 'custom';
    final displayText = isSelected && customDateRange != null 
        ? '${customDateRange!['start']!.day}/${customDateRange!['start']!.month} - ${customDateRange!['end']!.day}/${customDateRange!['end']!.month}'
        : 'Custom…';
    
    return GestureDetector(
      key: const Key('chipCustom'),
      onTap: _onCustomChipSelect,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  void _onChipSelect(String value) {
    setState(() {
      selectedDateRange = value;
      customDateRange = null;
    });
    refreshAnalytics();
  }
  
  void _onCustomChipSelect() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customDateRange != null 
          ? DateTimeRange(
              start: customDateRange!['start']!,
              end: customDateRange!['end']!,
            )
          : null,
    );
    
    if (picked != null) {
      setState(() {
        selectedDateRange = 'custom';
        customDateRange = {
          'start': picked.start,
          'end': picked.end,
        };
      });
      refreshAnalytics();
    }
  }
  
  Future<void> refreshAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Map selectedDateRange to service format
      String serviceRange;
      switch (selectedDateRange) {
        case 'last7':
          serviceRange = 'Last 7 days';
          break;
        case 'last30':
          serviceRange = 'Last 30 days';
          break;
        case 'last90':
          serviceRange = 'Last 90 days';
          break;
        case 'custom':
          serviceRange = 'Custom range';
          break;
        default:
          serviceRange = 'All time';
      }
      
      // Use actual service calls
      final analyticsService = AnalyticsService();
      final inventoryService = InventoryService();
      
      final results = await Future.wait([
        analyticsService.getFilteredAnalytics(serviceRange),
        analyticsService.fetchPerformanceInsights(),
        analyticsService.getChartAnalytics(serviceRange),
        inventoryService.getInventoryAnalytics(),
        _getOutstandingPaymentsData(),
      ]);
      
      setState(() {
        analyticsData = results[0] as List<Map<String, dynamic>>;
        performanceInsights = results[1] as Map<String, dynamic>;
        chartData = results[2] as Map<String, dynamic>;
        inventoryAnalytics = results[3] as Map<String, dynamic>;
        outstandingPayments = results[4] as Map<String, dynamic>;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics: ${e.toString()}';
      });
    }
  }

  Widget _buildQuickKpisSection() {
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
          Container(
            key: const Key('compactKpiCards'),
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _buildKpiCard(
                  title: 'Total Revenue',
                  value: _formatCurrency(_getTotalRevenue()),
                  delta: _getRevenueDelta(),
                  icon: Icons.trending_up,
                  onTap: () => _scrollToSection('revenue'),
                ),
                SizedBox(width: 12),
                _buildKpiCard(
                  title: 'Total Purchases',
                  value: _formatCurrency(_getTotalPurchases()),
                  icon: Icons.shopping_cart,
                  onTap: () => _scrollToSection('revenue'),
                ),
                SizedBox(width: 12),
                _buildKpiCard(
                  title: 'Outstanding',
                  value: _formatCurrency(_getOutstanding()),
                  icon: Icons.account_balance_wallet,
                  color: Colors.orange,
                  onTap: () => _scrollToSection('due'),
                ),
                SizedBox(width: 12),
                _buildKpiCard(
                  title: 'Total Clients',
                  value: _getTotalClients().toString(),
                  icon: Icons.people,
                  color: Colors.purple,
                  onTap: () => _scrollToSection('items'),
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
        padding: const EdgeInsets.all(16),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
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
  
  void _scrollToSection(String section) {
    // TODO: Implement smooth scrolling to sections
    // For now, just show a snackbar
    String sectionName;
    switch (section) {
      case 'revenue':
        sectionName = 'Revenue Section';
        break;
      case 'due':
        sectionName = 'Due Reminders Section';
        break;
      case 'items':
        sectionName = 'Items & Sales Insights Section';
        break;
      default:
        sectionName = 'Section';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scrolling to $sectionName'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildRevenueSection() {
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
          _buildTodaysRevenueCard(),
          SizedBox(height: 12),
          _buildItemRevenueCard(),
        ],
      ),
    );
  }
  
  Widget _buildTodaysRevenueCard() {
    final todayRevenue = _getTodaysRevenue();
    final yesterdayDelta = _getYesterdayDelta();
    
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
              Icon(Icons.today, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Today's Revenue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              _buildMiniSparkline(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(todayRevenue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'vs yesterday',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              if (yesterdayDelta != null) _buildDeltaBadge(yesterdayDelta),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemRevenueCard() {
    final topItems = _getTopSellingItems();
    
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
              Icon(Icons.bar_chart, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Item-wise Revenue Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showFullItemBreakdown,
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topItems.take(5).map((item) => _buildHorizontalBar(item)),
        ],
      ),
    );
  }
  
  Widget _buildHoldingCard() {
    final unsoldItems = _getUnsoldItems();
    
    return GestureDetector(
      onTap: () => _showUnsoldItemsModal(),
      child: Container(
        key: const Key('holdingCard'),
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
                Icon(Icons.schedule, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inventory Timeholding — Unsold Items Only',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${unsoldItems.length} items',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Currently unsold',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...unsoldItems.take(3).map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item['daysInStock']}d',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            if (unsoldItems.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+${unsoldItems.length - 3} more items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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
  
  // Revenue data methods
  double _getTodaysRevenue() {
    final revenueTrend = chartData['revenueTrend'] as List<dynamic>? ?? [];
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // First check actual data
    for (final item in revenueTrend) {
      if (item['date'] == todayStr) {
        return (item['revenue'] as double?) ?? 0.0;
      }
    }
    
    // Fallback: aggregate from latest trend data if available
    if (revenueTrend.isNotEmpty) {
      final latest = revenueTrend.first;
      return (latest['revenue'] as double?) ?? 0.0;
    }
    
    return 8450.0; // Sample data
  }
  
  double? _getYesterdayDelta() {
    final revenueTrend = chartData['revenueTrend'] as List<dynamic>? ?? [];
    if (revenueTrend.length < 2) return null;
    
    final today = revenueTrend.first['revenue'] as double? ?? 0.0;
    final yesterday = revenueTrend[1]['revenue'] as double? ?? 0.0;
    
    if (yesterday == 0) return null;
    return ((today - yesterday) / yesterday) * 100;
  }
  
  List<Map<String, dynamic>> _getTopSellingItems() {
    final topItems = chartData['topSellingItems'] as List<dynamic>? ?? [];
    return topItems.cast<Map<String, dynamic>>();
  }
  
  double _getMaxItemRevenue() {
    final items = _getTopSellingItems();
    if (items.isEmpty) return 1000.0;
    return items.map((e) => (e['revenue'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);
  }
  
  List<double> _getLast7DaysData() {
    final revenueTrend = chartData['revenueTrend'] as List<dynamic>? ?? [];
    if (revenueTrend.isEmpty) return [0, 0, 0, 0, 0, 0, 0];
    
    // Get last 7 days of data
    final last7Days = revenueTrend.take(7).map((item) => 
      (item['revenue'] as double?) ?? 0.0
    ).toList();
    
    // Pad with zeros if less than 7 days
    while (last7Days.length < 7) {
      last7Days.insert(0, 0.0);
    }
    
    return last7Days;
  }
  
  double _getAvgHoldingDays() {
    final inventoryValue = (inventoryAnalytics['totalValue'] as double?) ?? 124500.0;
    final dailySales = _getTodaysRevenue();
    
    // Zero division protection
    if (dailySales <= 0 || inventoryValue <= 0) {
      return 28.0; // Default estimate
    }
    
    // Estimate with 70% COGS, clamped to reasonable range
    return (inventoryValue / (dailySales * 0.7)).clamp(1.0, 365.0);
  }
  
  List<Map<String, dynamic>> _getUnsoldItems() {
    final slowMoving = inventoryAnalytics['slowMovingItems'] as List<dynamic>? ?? [];
    return slowMoving.where((item) => (item.currentStock ?? 0) > 0).map((item) {
      final lastUpdated = item.lastUpdated ?? DateTime.now().subtract(Duration(days: 30));
      final daysInStock = DateTime.now().difference(lastUpdated).inDays;
      return {
        'name': item.name ?? 'Unknown',
        'daysInStock': daysInStock,
        'quantity': (item.currentStock ?? 0).round(),
      };
    }).toList();
  }
  
  void _showUnsoldItemsModal() {
    final unsoldItems = _getUnsoldItems();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Unsold Inventory Items',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: unsoldItems.length,
                itemBuilder: (context, index) {
                  final item = unsoldItems[index];
                  final daysInStock = item['daysInStock'] as int;
                  Color statusColor = Colors.green;
                  if (daysInStock > 60) statusColor = Colors.red;
                  else if (daysInStock > 30) statusColor = Colors.orange;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${item['quantity']} units',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$daysInStock days',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              'in stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFullItemBreakdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Item-wise Revenue Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _getTopSellingItems().length,
                itemBuilder: (context, index) {
                  final item = _getTopSellingItems()[index];
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency((item['revenue'] as double?) ?? 0.0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item['quantitySold'] ?? 0} units',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              width: _getMaxItemRevenue() > 0 ? ((item['revenue'] as double?) ?? 0.0) / _getMaxItemRevenue() * double.infinity : 0,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsInsightsSection() {
    return Container(
      key: const Key('itemsInsightsSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items & Sales Insights',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          _buildInvoiceMixCard(),
          SizedBox(height: 12),
          _buildBestSellingItemsCard(),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCustomersCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoriesCard()),
            ],
          ),
          SizedBox(height: 12),
          _buildTrendsCard(),
        ],
      ),
    );
  }
  
  Widget _buildInvoiceMixCard() {
    final invoiceBreakdown = _getInvoiceTypeBreakdown();
    
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
              Icon(Icons.receipt_long, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Invoice Mix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Count comparison
          Row(
            children: [
              Expanded(
                child: _buildMiniBar(
                  'Sales',
                  invoiceBreakdown['salesCount'] ?? 0,
                  Colors.blue,
                  invoiceBreakdown['salesCount'] + invoiceBreakdown['purchaseCount'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniBar(
                  'Purchase',
                  invoiceBreakdown['purchaseCount'] ?? 0,
                  Colors.green,
                  invoiceBreakdown['salesCount'] + invoiceBreakdown['purchaseCount'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Revenue comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Revenue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatCurrency(invoiceBreakdown['salesRevenue'] ?? 0.0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatCurrency(invoiceBreakdown['purchaseRevenue'] ?? 0.0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBestSellingItemsCard() {
    final topItems = _getBestSellingItems();
    
    return GestureDetector(
      onTap: _showBestSellingItemsModal,
      child: Container(
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
                Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Best-Selling Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topItems.take(5).toList().asMap().entries.map(
              (entry) => _buildRankedItem(entry.key + 1, entry.value),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomersCard() {
    final insights = _getInsights();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.people, color: Colors.purple, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Customers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insights['totalClients']?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            'Total Clients',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesCard() {
    final insights = _getInsights();
    final categoryPerformance = _getCategoryPerformance();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.category, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insights['totalCategories']?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            'Total Categories',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryPerformance.take(2).map(
            (category) => _buildCategoryItem(category),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendsCard() {
    final trends = _getTrends();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.show_chart, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Trends',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTrendTile(
            'Revenue Change',
            trends['revenueChange'] ?? 0.0,
            '30-day comparison',
          ),
          const SizedBox(height: 12),
          _buildTrendTile(
            'Items Sold Change',
            trends['itemsSoldChange'] ?? 0.0,
            'vs previous period',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniBar(String label, int value, Color color, int total) {
    // Zero division protection
    final percentage = (total > 0 && value >= 0) ? (value / total).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 4,
              width: (percentage * 100).clamp(0.0, 100.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRankedItem(int rank, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
            _formatCurrency((item['revenue'] as double?) ?? 0.0),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category.keys.first;
    final data = category[name] as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '₹${((data['totalRevenue'] as double?) ?? 0.0 / 1000).toStringAsFixed(0)}K',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendTile(String title, double value, String subtitle) {
    final isPositive = value >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ],
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
  
  // Data extraction methods for Items & Sales Insights
  Map<String, dynamic> _getInvoiceTypeBreakdown() {
    final breakdown = performanceInsights['invoiceTypeBreakdown'] as Map<String, dynamic>? ?? {};
    return {
      'salesCount': breakdown['salesCount'] ?? 0,
      'purchaseCount': breakdown['purchaseCount'] ?? 0,
      'salesRevenue': breakdown['salesRevenue'] ?? 0.0,
      'purchaseRevenue': breakdown['purchaseRevenue'] ?? 0.0,
    };
  }
  
  List<Map<String, dynamic>> _getBestSellingItems() {
    final items = performanceInsights['topRevenueItems'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }
  
  Map<String, dynamic> _getInsights() {
    final insights = performanceInsights['insights'] as Map<String, dynamic>? ?? {};
    return {
      'totalClients': insights['totalClients'] ?? 0,
      'totalCategories': insights['totalCategories'] ?? 0,
    };
  }
  
  List<Map<String, dynamic>> _getCategoryPerformance() {
    final categoryPerformance = performanceInsights['categoryPerformance'] as Map<String, dynamic>? ?? {};
    return categoryPerformance.entries.map((e) => {e.key: e.value}).toList();
  }
  
  Map<String, dynamic> _getTrends() {
    final trends = performanceInsights['trends'] as Map<String, dynamic>? ?? {};
    return {
      'revenueChange': trends['revenueChange'] ?? 0.0,
      'itemsSoldChange': trends['itemsSoldChange'] ?? 0.0,
    };
  }
  
  void _showBestSellingItemsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Best-Selling Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _getBestSellingItems().length,
                itemBuilder: (context, index) {
                  final item = _getBestSellingItems()[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Qty: ${item['quantitySold'] ?? 0} units',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency((item['revenue'] as double?) ?? 0.0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Container(
      key: const Key('inventorySection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Analytics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          _buildInventorySummaryCard(),
          SizedBox(height: 16),
          _buildMovementHealthCard(),
          SizedBox(height: 16),
          _buildHoldingCard(),
        ],
      ),
    );
  }
  
  Widget _buildInventorySummaryCard() {
    final totalItems = inventoryAnalytics['totalItems'] ?? 0;
    final inventoryValue = inventoryAnalytics['totalValue'] ?? 0.0;
    final lowStockCount = inventoryAnalytics['lowStockCount'] ?? 0;
    final avgStockValue = inventoryAnalytics['averageStockValue'] ?? 0.0;
    
    return Container(
      width: double.infinity,
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
              Icon(Icons.inventory_2, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Inventory Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildVerticalMetric('Total Items', totalItems.toString()),
          const SizedBox(height: 16),
          _buildVerticalMetric('Inventory Value', _formatCurrency(inventoryValue)),
          const SizedBox(height: 16),
          _buildLowStockMetric('Low-Stock Items', lowStockCount),
          const SizedBox(height: 16),
          _buildVerticalMetric('Avg/Item', '₹${avgStockValue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
  
  Widget _buildMovementHealthCard() {
    final fastMoving = _getFastMovingItems();
    final slowMoving = _getSlowMovingItems();
    
    return Container(
      width: double.infinity,
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
              Icon(Icons.trending_up, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Movement Health',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.north_east, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Fast Moving',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fastMoving.take(3).map((item) => _buildMovementItem(
            item['name'] ?? 'Unknown',
            '${item['turnoverRate']?.toStringAsFixed(1) ?? '0'}x',
            Colors.green[600]!,
            () => _navigateToInventoryDetail(item),
          )),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Slow Moving',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...slowMoving.take(3).map((item) => _buildMovementItem(
            item['name'] ?? 'Unknown',
            '${item['daysInStock'] ?? 0}d old',
            Colors.orange[600]!,
            () => _navigateToInventoryDetail(item),
          )),
        ],
      ),
    );
  }
  

  
  List<Map<String, dynamic>> _getFastMovingItems() {
    final fastMoving = inventoryAnalytics['fastMovingItems'] as List<dynamic>? ?? [];
    return fastMoving.map((item) => {
      'name': item['item']?.name ?? 'Unknown Item',
      'turnoverRate': item['turnoverRate'] ?? 0.0,
      'id': item['item']?.id ?? 'unknown',
    }).toList();
  }
  
  List<Map<String, dynamic>> _getSlowMovingItems() {
    final slowMoving = inventoryAnalytics['slowMovingItems'] as List<dynamic>? ?? [];
    return slowMoving.map((item) => {
      'name': item.name ?? 'Unknown Item',
      'turnoverRate': 0.0,
      'id': item.id ?? 'unknown',
      'daysInStock': DateTime.now().difference(item.lastUpdated ?? DateTime.now().subtract(Duration(days: 30))).inDays,
    }).toList();
  }
  
  void _navigateToInventoryDetail(Map<String, dynamic> item) {
    Navigator.pushNamed(
      context,
      '/inventory_detail',
      arguments: {'itemId': item['id']},
    );
  }
  
  Widget _buildVerticalMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLowStockMetric(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: count > 0 ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMovementItem(String name, String rate, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              rate,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Due Reminders data methods
  List<Map<String, dynamic>> _getOverdueCustomerBuckets() {
    final buckets = outstandingPayments['customerBuckets'] as Map<String, dynamic>? ?? {};
    return [
      {
        'label': '1-7 days',
        'count': buckets['1-7']?['count'] ?? 5,
        'amount': buckets['1-7']?['amount'] ?? 12500.0,
        'color': Colors.orange,
        'key': '1-7',
      },
      {
        'label': '8-30 days',
        'count': buckets['8-30']?['count'] ?? 8,
        'amount': buckets['8-30']?['amount'] ?? 28000.0,
        'color': Colors.red,
        'key': '8-30',
      },
      {
        'label': '31-60 days',
        'count': buckets['31-60']?['count'] ?? 3,
        'amount': buckets['31-60']?['amount'] ?? 15200.0,
        'color': Colors.red[700],
        'key': '31-60',
      },
      {
        'label': '60+ days',
        'count': buckets['60+']?['count'] ?? 2,
        'amount': buckets['60+']?['amount'] ?? 8900.0,
        'color': Colors.red[900],
        'key': '60+',
      },
    ];
  }
  
  List<Map<String, dynamic>> _getOverdueItemBuckets() {
    final buckets = outstandingPayments['itemBuckets'] as Map<String, dynamic>? ?? {};
    return [
      {
        'label': '1-7 days',
        'count': buckets['1-7']?['count'] ?? 12,
        'amount': buckets['1-7']?['amount'] ?? 8500.0,
        'color': Colors.orange,
        'key': '1-7',
      },
      {
        'label': '8-30 days',
        'count': buckets['8-30']?['count'] ?? 18,
        'amount': buckets['8-30']?['amount'] ?? 22000.0,
        'color': Colors.red,
        'key': '8-30',
      },
      {
        'label': '31-60 days',
        'count': buckets['31-60']?['count'] ?? 7,
        'amount': buckets['31-60']?['amount'] ?? 11200.0,
        'color': Colors.red[700],
        'key': '31-60',
      },
      {
        'label': '60+ days',
        'count': buckets['60+']?['count'] ?? 4,
        'amount': buckets['60+']?['amount'] ?? 6800.0,
        'color': Colors.red[900],
        'key': '60+',
      },
    ];
  }
  
  void _showCustomerBucketDetail(Map<String, dynamic> bucket) {
    final customers = _getCustomersInBucket(bucket['key']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: bucket['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Customers - ${bucket['label']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${bucket['count']} customers • ${_formatCurrency(bucket['amount'])}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Dismissible(
                    key: Key('customer_${customer['name']}_$index'),
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.email, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.green,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.phone, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _sendReminder(customer);
                      } else {
                        _callCustomer(customer);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          customer['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${customer['invoiceCount']} unpaid invoices'),
                            Text(
                              'Last invoice: ${customer['lastInvoiceDate']}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(customer['amount']),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: bucket['color'],
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _viewLedger(customer),
                              child: const Text('View Ledger', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showItemBucketDetail(Map<String, dynamic> bucket) {
    final items = _getItemsInBucket(bucket['key']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: bucket['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Items - ${bucket['label']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${bucket['count']} items • ${_formatCurrency(bucket['amount'])}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['debtorCount']} debtors'),
                          Text(
                            'Last sold: ${item['lastSoldDate']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Text(
                        _formatCurrency(item['amount']),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: bucket['color'],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Map<String, dynamic>> _getCustomersInBucket(String bucketKey) {
    final customers = outstandingPayments['customers'] as List<dynamic>? ?? [];
    return customers
        .where((c) => c['daysBucket'] == bucketKey)
        .cast<Map<String, dynamic>>()
        .toList();
  }
  
  List<Map<String, dynamic>> _getItemsInBucket(String bucketKey) {
    final items = outstandingPayments['items'] as List<dynamic>? ?? [];
    return items
        .where((i) => i['daysBucket'] == bucketKey)
        .cast<Map<String, dynamic>>()
        .toList();
  }
  
  // Action methods
  void _sendReminder(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sent to ${customer['name']}')),
    );
  }
  
  void _callCustomer(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${customer['name']}')),
    );
  }
  
  void _viewLedger(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ledger for ${customer['name']}')),
    );
  }
  
  void _generateRemindersPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating reminders PDF...')),
    );
  }
  
  void _shareSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing summary...')),
    );
  }
  
  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting CSV...')),
    );
  }

  Widget _buildDueRemindersSection() {
    return Container(
      key: const Key('dueRemindersSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due Reminders',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          _buildDueRemindersCard(),
        ],
      ),
    );
  }
  
  Widget _buildDueRemindersCard() {
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
              Icon(Icons.notifications_active, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Outstanding Payments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showDueRemindersModal,
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDueSummaryTile(
                  'Total Outstanding',
                  _formatCurrency(_getTotalOutstanding()),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDueSummaryTile(
                  'Overdue Customers',
                  _getOverdueCustomersCount().toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDueSummaryTile(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
  
  double _getTotalOutstanding() {
    final buckets = outstandingPayments['customerBuckets'] as Map<String, dynamic>? ?? {};
    double total = 0.0;
    buckets.values.forEach((bucket) {
      total += (bucket['amount'] as double?) ?? 0.0;
    });
    return total;
  }
  
  int _getOverdueCustomersCount() {
    final buckets = outstandingPayments['customerBuckets'] as Map<String, dynamic>? ?? {};
    int total = 0;
    buckets.values.forEach((bucket) {
      total += (bucket['count'] as int?) ?? 0;
    });
    return total;
  }
  
  void _showDueRemindersModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DueRemindersScreen(
          outstandingPayments: outstandingPayments,
          formatCurrency: _formatCurrency,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTableCard() {
    return Container(
      key: const Key('analyticsTableCard'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: GestureDetector(
        onTap: _showAnalyticsTableModal,
        child: Container(
          height: 88,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.blue.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.table_chart,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analytics Table',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Open full table with search & filters',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAnalyticsTableModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Analytics Table'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: Container(
            child: _buildAnalyticsTableWidget(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnalyticsTableWidget() {
    return AnalyticsTableWidget(
      data: _getAnalyticsTableData(),
      searchQuery: _searchQuery,
      sortColumn: _sortColumn,
      sortAscending: _sortAscending,
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      onSortChanged: (column) {
        setState(() {
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = false;
          }
        });
      },
    );
  }
  
  String _getDateRangeText() {
    switch (selectedDateRange) {
      case 'last7':
        return 'Last 7 days';
      case 'last30':
        return 'Last 30 days';
      case 'last90':
        return 'Last 3 months';
      case 'custom':
        if (customDateRange != null) {
          final start = customDateRange!['start']!;
          final end = customDateRange!['end']!;
          return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
        }
        return 'Custom range';
      default:
        return 'All time';
    }
  }
  
  List<Map<String, dynamic>> _getAnalyticsTableData() {
    return analyticsData;
  }
  
  Future<Map<String, dynamic>> _getOutstandingPaymentsData() async {
    try {
      final dbService = DatabaseService();
      final customerService = CustomerService();
      
      // Get all invoices with outstanding amounts
      final allInvoices = await dbService.getAllInvoices();
      final outstandingInvoices = allInvoices.where((inv) => 
        inv.invoiceType == 'sales' && inv.remainingAmount > 0
      ).toList();
      
      // Group customers by overdue buckets
      Map<String, Map<String, dynamic>> customerBuckets = {
        '1-7': {'count': 0, 'amount': 0.0},
        '8-30': {'count': 0, 'amount': 0.0},
        '31-60': {'count': 0, 'amount': 0.0},
        '60+': {'count': 0, 'amount': 0.0},
      };
      
      Map<String, Map<String, dynamic>> itemBuckets = {
        '1-7': {'count': 0, 'amount': 0.0},
        '8-30': {'count': 0, 'amount': 0.0},
        '31-60': {'count': 0, 'amount': 0.0},
        '60+': {'count': 0, 'amount': 0.0},
      };
      
      List<Map<String, dynamic>> customers = [];
      List<Map<String, dynamic>> items = [];
      
      // Group by customer
      Map<String, List<dynamic>> customerInvoices = {};
      for (final invoice in outstandingInvoices) {
        customerInvoices.putIfAbsent(invoice.clientName, () => []).add(invoice);
      }
      
      // Process customer data
      for (final entry in customerInvoices.entries) {
        final customerName = entry.key;
        final invoices = entry.value;
        
        double totalAmount = 0.0;
        DateTime? oldestDate;
        
        for (final invoice in invoices) {
          totalAmount += invoice.remainingAmount;
          if (oldestDate == null || invoice.date.isBefore(oldestDate)) {
            oldestDate = invoice.date;
          }
        }
        
        if (oldestDate != null) {
          final daysDiff = DateTime.now().difference(oldestDate).inDays;
          String bucket = '60+';
          if (daysDiff <= 7) bucket = '1-7';
          else if (daysDiff <= 30) bucket = '8-30';
          else if (daysDiff <= 60) bucket = '31-60';
          
          customerBuckets[bucket]!['count'] += 1;
          customerBuckets[bucket]!['amount'] += totalAmount;
          
          customers.add({
            'name': customerName,
            'amount': totalAmount,
            'invoiceCount': invoices.length,
            'lastInvoiceDate': oldestDate.toIso8601String().split('T')[0],
            'daysBucket': bucket,
          });
        }
      }
      
      // Process item data - Fixed to reflect true dates and amounts
      Map<String, Map<String, dynamic>> itemOutstanding = {};
      
      for (final invoice in outstandingInvoices) {
      // Calculate the actual invoice total from line items
      double invoiceLineItemsTotal = 0.0;
      for (final item in invoice.items) {
      final quantity = item.quantity ?? 0;
      final price = item.price ?? 0.0;
      invoiceLineItemsTotal += (price * quantity);
      }
      
      // Skip if no line items total (avoid division by zero)
      if (invoiceLineItemsTotal <= 0) continue;
      
      // Calculate the outstanding percentage for this invoice
      final outstandingPercentage = invoice.remainingAmount / invoiceLineItemsTotal;
      
      for (final item in invoice.items) {
      final itemName = item.name ?? 'Unknown Item';
      final quantity = item.quantity ?? 0;
      final price = item.price ?? 0.0;
      final itemLineTotal = price * quantity;
      
      // Calculate the outstanding amount for this specific item
      final itemOutstandingAmount = itemLineTotal * outstandingPercentage;
      
      // Skip items with zero outstanding amount
      if (itemOutstandingAmount <= 0) continue;
      
      // Initialize item data if not exists
      if (!itemOutstanding.containsKey(itemName)) {
      itemOutstanding[itemName] = {
      'totalAmount': 0.0,
      'debtors': <String>{},
      'invoiceDates': <DateTime>[],
      'invoiceDetails': <Map<String, dynamic>>[],
      };
      }
      
      // Add to item outstanding data
      itemOutstanding[itemName]!['totalAmount'] += itemOutstandingAmount;
      (itemOutstanding[itemName]!['debtors'] as Set<String>).add(invoice.clientName);
      (itemOutstanding[itemName]!['invoiceDates'] as List<DateTime>).add(invoice.date);
      (itemOutstanding[itemName]!['invoiceDetails'] as List<Map<String, dynamic>>).add({
      'invoiceId': invoice.id,
      'clientName': invoice.clientName,
      'date': invoice.date,
      'amount': itemOutstandingAmount,
      'quantity': quantity,
      'price': price,
      });
      }
      }
      
      // Process the collected item data
      for (final entry in itemOutstanding.entries) {
      final itemName = entry.key;
      final itemData = entry.value;
      
      final totalAmount = itemData['totalAmount'] as double;
      final debtors = itemData['debtors'] as Set<String>;
      final invoiceDates = itemData['invoiceDates'] as List<DateTime>;
      
      // Find the oldest invoice date for this item
      DateTime oldestDate = invoiceDates.first;
      for (final date in invoiceDates) {
      if (date.isBefore(oldestDate)) {
      oldestDate = date;
      }
      }
      
      // Calculate days difference from the oldest invoice
      final daysDiff = DateTime.now().difference(oldestDate).inDays;
      String bucket = '60+';
      if (daysDiff <= 7) bucket = '1-7';
      else if (daysDiff <= 30) bucket = '8-30';
      else if (daysDiff <= 60) bucket = '31-60';
      
      itemBuckets[bucket]!['count'] += 1;
      itemBuckets[bucket]!['amount'] += totalAmount;
      
      items.add({
      'name': itemName,
      'amount': totalAmount,
      'debtorCount': debtors.length,
      'lastSoldDate': oldestDate.toIso8601String().split('T')[0],
      'daysBucket': bucket,
      'invoiceDetails': itemData['invoiceDetails'], // Include detailed invoice info
      });
      }
      
      // Sort by amount descending
      customers.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      items.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      
      return {
        'customerBuckets': customerBuckets,
        'itemBuckets': itemBuckets,
        'customers': customers,
        'items': items,
      };
    } catch (e) {
      print('Error getting outstanding payments: $e');
      return {
        'customerBuckets': {},
        'itemBuckets': {},
        'customers': [],
        'items': [],
      };
    }
  }
}

class _DueRemindersScreen extends StatefulWidget {
  final Map<String, dynamic> outstandingPayments;
  final String Function(double) formatCurrency;
  
  const _DueRemindersScreen({
    required this.outstandingPayments,
    required this.formatCurrency,
  });
  
  @override
  State<_DueRemindersScreen> createState() => _DueRemindersScreenState();
}

class _DueRemindersScreenState extends State<_DueRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Due Reminders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'Customer-wise Dues'),
            Tab(text: 'Item-wise Dues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerDuesList(),
          _buildItemDuesList(),
        ],
      ),
    );
  }
  
  Widget _buildCustomerDuesList() {
    final customers = _getAllCustomers();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final daysOverdue = _calculateDaysOverdue(customer['lastInvoiceDate']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              customer['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${customer['invoiceCount']} unpaid invoices'),
                Text(
                  '$daysOverdue days overdue',
                  style: TextStyle(
                    color: _getOverdueColor(daysOverdue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.formatCurrency(customer['amount']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            onTap: () => _showCustomerDetail(customer),
          ),
        );
      },
    );
  }
  
  Widget _buildItemDuesList() {
    final items = _getAllItems();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final oldestDate = _getOldestInvoiceDate(item['name']);
        final daysOverdue = _calculateDaysOverdue(oldestDate);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              item['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${item['debtorCount']} customers owe for this item'),
                Text(
                  'Oldest invoice: $oldestDate ($daysOverdue days)',
                  style: TextStyle(
                    color: _getOverdueColor(daysOverdue),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Text(
              widget.formatCurrency(item['amount']),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            onTap: () => _showItemDetail(item),
          ),
        );
      },
    );
  }
  
  List<Map<String, dynamic>> _getAllCustomers() {
    final customers = widget.outstandingPayments['customers'] as List<dynamic>? ?? [];
    final customerList = customers.cast<Map<String, dynamic>>();
    
    // Sort by highest amount due
    customerList.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    return customerList;
  }
  
  List<Map<String, dynamic>> _getAllItems() {
    final items = widget.outstandingPayments['items'] as List<dynamic>? ?? [];
    final itemList = items.cast<Map<String, dynamic>>();
    
    // Sort by highest amount due
    itemList.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    return itemList;
  }
  
  int _calculateDaysOverdue(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return now.difference(date).inDays;
    } catch (e) {
      return 0;
    }
  }
  
  Color _getOverdueColor(int days) {
    if (days > 60) return Colors.red;
    if (days > 30) return Colors.orange;
    if (days > 7) return Colors.amber;
    return Colors.green;
  }
  
  void _showCustomerDetail(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Total Due: ${widget.formatCurrency(customer['amount'])}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unpaid Invoices',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildInvoiceItem('INV-001', '2024-01-10', 2500.0),
                    _buildInvoiceItem('INV-002', '2024-01-08', 2700.0),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _sendReminder(customer),
                            icon: const Icon(Icons.email),
                            label: const Text('Send Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callCustomer(customer),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvoiceItem(String invoiceNo, String date, double amount) {
    final daysOverdue = _calculateDaysOverdue(date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Text(
                '$daysOverdue days',
                style: TextStyle(
                  fontSize: 12,
                  color: _getOverdueColor(daysOverdue),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _sendReminder(Map<String, dynamic> customer) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sent to ${customer['name']}')),
    );
  }
  
  void _callCustomer(Map<String, dynamic> customer) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${customer['name']}')),
    );
  }
  
  String _getOldestInvoiceDate(String itemName) {
  // Get the actual oldest invoice date for this item from our data
  final items = widget.outstandingPayments['items'] as List<dynamic>? ?? [];
  
  for (final item in items) {
  if (item['name'] == itemName) {
  return item['lastSoldDate'] ?? '2024-01-01';
  }
  }
  
  return '2024-01-01'; // Fallback date
  }
  
  void _showItemDetail(Map<String, dynamic> item) {
    final customersForItem = _getCustomersForItem(item['name']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Total Due: ${widget.formatCurrency(item['amount'])} • ${item['debtorCount']} customers',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: customersForItem.length,
                itemBuilder: (context, index) {
                  final customerDebt = customersForItem[index];
                  final daysOverdue = _calculateDaysOverdue(customerDebt['invoiceDate']);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerDebt['customerName'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Invoice: ${customerDebt['invoiceNo']} • ${customerDebt['invoiceDate']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$daysOverdue days overdue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getOverdueColor(daysOverdue),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.formatCurrency(customerDebt['amount']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Map<String, dynamic>> _getCustomersForItem(String itemName) {
    // Sample data - in real app, fetch customers who owe for this specific item
    final sampleData = {
      'Rice Bag 25kg': [
        {'customerName': 'ABC Store', 'amount': 1200.0, 'invoiceNo': 'INV-001', 'invoiceDate': '2024-01-12'},
        {'customerName': 'XYZ Mart', 'amount': 800.0, 'invoiceNo': 'INV-003', 'invoiceDate': '2024-01-10'},
        {'customerName': 'Quick Shop', 'amount': 400.0, 'invoiceNo': 'INV-005', 'invoiceDate': '2024-01-08'},
      ],
      'Wheat Flour 10kg': [
        {'customerName': 'Super Market', 'amount': 950.0, 'invoiceNo': 'INV-002', 'invoiceDate': '2024-01-09'},
        {'customerName': 'Corner Store', 'amount': 850.0, 'invoiceNo': 'INV-004', 'invoiceDate': '2024-01-07'},
      ],
      'Sugar 1kg': [
        {'customerName': 'ABC Store', 'amount': 1500.0, 'invoiceNo': 'INV-006', 'invoiceDate': '2023-12-28'},
        {'customerName': 'Quick Shop', 'amount': 1200.0, 'invoiceNo': 'INV-007', 'invoiceDate': '2023-12-25'},
        {'customerName': 'XYZ Mart', 'amount': 900.0, 'invoiceNo': 'INV-008', 'invoiceDate': '2023-12-20'},
        {'customerName': 'Super Market', 'amount': 600.0, 'invoiceNo': 'INV-009', 'invoiceDate': '2023-12-15'},
        {'customerName': 'Corner Store', 'amount': 300.0, 'invoiceNo': 'INV-010', 'invoiceDate': '2023-12-10'},
      ],
    };
    
    return sampleData[itemName] ?? [
      {'customerName': 'Sample Customer', 'amount': 500.0, 'invoiceNo': 'INV-000', 'invoiceDate': '2024-01-01'},
    ];
  }
}
