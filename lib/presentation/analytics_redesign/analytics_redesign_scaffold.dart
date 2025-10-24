import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sparkline_painter.dart';
import 'widgets/skeleton_loader.dart';
import '../analytics_screen/widgets/analytics_table_widget.dart';
import '../../services/analytics_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/firestore_service.dart';
import 'item_wise_revenue_screen.dart';
import 'customer_wise_revenue_screen.dart';
 

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
  List<Map<String, dynamic>> customerAnalyticsData = [];
  Map<String, dynamic> performanceInsights = {};
  Map<String, dynamic> chartData = {};
  Map<String, dynamic> inventoryAnalytics = {};
  Map<String, dynamic> outstandingPayments = {};

  // Revenue breakdown toggle state
  bool _isCustomerWiseView = false;

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
    return _isLoading
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
            _buildDateChip('Today', 'chipToday', 'today'),
            SizedBox(width: 8),
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
        case 'today':
          serviceRange = 'Today';
          break;
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
        analyticsService.getCustomerWiseRevenue(serviceRange),
        analyticsService.fetchPerformanceInsights(serviceRange),
        analyticsService.getChartAnalytics(serviceRange),
        inventoryService.getInventoryAnalytics(),
        _getOutstandingPaymentsData(serviceRange),
      ]);

      setState(() {
        analyticsData = results[0] as List<Map<String, dynamic>>;
        customerAnalyticsData = results[1] as List<Map<String, dynamic>>;
        performanceInsights = results[2] as Map<String, dynamic>;
        chartData = results[3] as Map<String, dynamic>;
        inventoryAnalytics = results[4] as Map<String, dynamic>;
        outstandingPayments = results[5] as Map<String, dynamic>;
        _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load analytics: ${e.toString()}';
        });
      }
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
          _isLoading
              ? Container(
                  height: 100,
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
          _isLoading
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
  
  Widget _buildHoldingCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getUnsoldItems(),
      builder: (context, snapshot) {
        final unsoldItems = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        
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
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isLoading ? 'Loading...' : '${unsoldItems.length} items',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: unsoldItems.isEmpty ? Colors.green : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? 'Checking inventory...' : 
                  (unsoldItems.isEmpty ? 'All items moving well' : 'Currently unsold'),
                  style: TextStyle(
                    fontSize: 14,
                    color: unsoldItems.isEmpty ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
                if (!isLoading && unsoldItems.isNotEmpty) ...[
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
                            item['ageLabel'] ?? '${item['daysInStock']}d',
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
                ] else if (!isLoading && unsoldItems.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Great! No stagnant inventory',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
  
  // Revenue data methods
  double _getPeriodRevenue() {
    // Get total revenue for the selected date range
    final salesVsPurchases = chartData['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    final salesRevenue = (salesVsPurchases['sales'] as double?) ?? 0.0;
    return salesRevenue;
  }

  String _getRevenueCardLabel() {
    switch (selectedDateRange) {
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
    final revenueTrend = chartData['revenueTrend'] as List<dynamic>? ?? [];
    final invoiceTypeBreakdown = chartData['invoiceTypeBreakdown'] as Map<String, dynamic>?;

    if (invoiceTypeBreakdown != null) {
      final salesCount = invoiceTypeBreakdown['salesCount'] as int? ?? 0;
      final purchaseCount = invoiceTypeBreakdown['purchaseCount'] as int? ?? 0;
      return '$salesCount sales, $purchaseCount purchases';
    }

    return '${revenueTrend.length} transaction days';
  }

  double _getTodaysRevenue() {
    // Legacy method - now just returns period revenue
    return _getPeriodRevenue();
  }

  double? _getYesterdayDelta() {
    // Legacy method - deprecated
    return null;
  }
  
  List<Map<String, dynamic>> _getTopSellingItems() {
    final topItems = chartData['topSellingItems'] as List<dynamic>? ?? [];
    return topItems.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _getTopCustomers() {
    // This will be populated by refreshAnalytics
    return customerAnalyticsData;
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
    final periodRevenue = _getPeriodRevenue();

    // Calculate number of days in the selected period
    int daysInPeriod;
    switch (selectedDateRange) {
      case 'today':
        daysInPeriod = 1;
        break;
      case 'last7':
        daysInPeriod = 7;
        break;
      case 'last30':
        daysInPeriod = 30;
        break;
      case 'last90':
        daysInPeriod = 90;
        break;
      default:
        daysInPeriod = 30; // Default to 30 days
    }

    // Calculate average daily sales
    final dailySales = daysInPeriod > 0 ? periodRevenue / daysInPeriod : 0.0;

    // Zero division protection
    if (dailySales <= 0 || inventoryValue <= 0) {
      return 28.0; // Default estimate
    }

    // Estimate with 70% COGS, clamped to reasonable range
    return (inventoryValue / (dailySales * 0.7)).clamp(1.0, 365.0);
  }
  
  Future<List<Map<String, dynamic>>> _getUnsoldItems() async {
    try {
      final inventoryService = InventoryService();
      final fs = FirestoreService.instance;
      
      // Get all items with stock > 0
      final allItems = await inventoryService.getAllItems();
      final itemsWithStock = allItems.where((item) => item.currentStock > 0).toList();
      
      if (itemsWithStock.isEmpty) return [];
      
      // Get all invoices to find last transaction dates
      final allInvoices = await fs.getAllInvoices();
      
      List<Map<String, dynamic>> unsoldItems = [];
      
      for (final item in itemsWithStock) {
        // Find the most recent transaction for this item
        DateTime? lastTransactionDate;
        
        for (final invoice in allInvoices) {
          for (final invoiceItem in invoice.items) {
            if (invoiceItem.name == item.name) {
              if (lastTransactionDate == null || invoice.date.isAfter(lastTransactionDate)) {
                lastTransactionDate = invoice.date;
              }
            }
          }
        }
        
        // Use last transaction date or item creation date
        final unsoldSinceDate = lastTransactionDate ?? item.lastUpdated;
        final now = DateTime.now();
        final ageInHours = now.difference(unsoldSinceDate).inHours;
        final ageInDays = now.difference(unsoldSinceDate).inDays;
        
        // Calculate age label based on requirements
        String ageLabel;
        if (ageInHours < 24) {
          ageLabel = 'Unsold ${ageInHours}h';
        } else if (ageInDays < 30) {
          ageLabel = 'Unsold ${ageInDays}d';
        } else if (ageInDays < 365) {
          final months = (ageInDays / 30).floor();
          ageLabel = 'Unsold ${months}mo';
        } else {
          final years = (ageInDays / 365).floor();
          ageLabel = 'Unsold ${years}y';
        }
        
        unsoldItems.add({
          'name': item.name,
          'daysInStock': ageInDays,
          'ageLabel': ageLabel,
          'quantity': item.currentStock.round(),
          'ageInHours': ageInHours,
          'unsoldSince': unsoldSinceDate,
        });
      }
      
      // Sort by age (oldest first)
      unsoldItems.sort((a, b) => (b['ageInHours'] as int).compareTo(a['ageInHours'] as int));
      
      return unsoldItems;
    } catch (e) {
      print('Error getting unsold items: $e');
      return [];
    }
  }
  
  void _showUnsoldItemsModal() async {
    final unsoldItems = await _getUnsoldItems();
    
    if (unsoldItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unsold items found')),
      );
      return;
    }
    
    final groupedItems = _groupItemsByAge(unsoldItems);
    
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Timeholding - Unsold Items',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${unsoldItems.length} items currently unsold',
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
              child: groupedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No items to group',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedItems.length,
                      itemBuilder: (context, index) {
                        final group = groupedItems[index];
                        final items = group['items'] as List<Map<String, dynamic>>;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: group['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${group['label']} (${items.length} items)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: group['color'],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) => Container(
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
                                            item['name'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Qty: ${item['quantity']} units',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item['ageLabel'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: group['color'],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
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
  
  List<Map<String, dynamic>> _groupItemsByAge(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return [];
    
    final groups = <String, List<Map<String, dynamic>>>{};
    
    for (final item in items) {
      final ageInHours = item['ageInHours'] as int? ?? 0;
      final ageInDays = item['daysInStock'] as int? ?? 0;
      
      String groupKey;
      if (ageInHours < 24) {
        groupKey = ageInHours == 0 ? 'Added Today' : 'Last 24 Hours';
      } else if (ageInDays < 7) {
        groupKey = 'Last Week';
      } else if (ageInDays < 30) {
        groupKey = 'Last Month';
      } else if (ageInDays < 365) {
        groupKey = 'Last Year';
      } else {
        groupKey = 'Over 1 Year';
      }
      
      groups.putIfAbsent(groupKey, () => []).add(item);
    }
    
    final groupOrder = ['Added Today', 'Last 24 Hours', 'Last Week', 'Last Month', 'Last Year', 'Over 1 Year'];
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.red, Colors.purple, Colors.grey];
    
    return groupOrder.asMap().entries.where((entry) => groups.containsKey(entry.value)).map((entry) => {
      'label': entry.value,
      'items': groups[entry.value]!,
      'color': colors[entry.key],
    }).toList();
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
    switch (selectedDateRange) {
      case 'today':
        return 'Today';
      case 'last7':
        return 'Last 7 Days';
      case 'last30':
        return 'Last 30 Days';
      case 'last90':
        return 'Last 90 Days';
      case 'custom':
        return 'Custom Range';
      default:
        return 'All Time';
    }
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
          _isLoading
              ? Column(
                  children: [
                    SkeletonLoader.kpiCard(icon: Icons.receipt_long, color: Colors.blue),
                    SizedBox(height: 12),
                    SkeletonLoader.kpiCard(icon: Icons.star, color: Colors.orange),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.kpiCard(icon: Icons.people, color: Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: SkeletonLoader.kpiCard(icon: Icons.category, color: Colors.teal)),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonLoader.kpiCard(icon: Icons.trending_up, color: Colors.green),
                  ],
                )
              : Column(
                  children: [
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
          _isLoading
              ? Column(
                  children: [
                    SkeletonLoader.inventoryCard(),
                    SizedBox(height: 16),
                    SkeletonLoader.kpiCard(icon: Icons.inventory, color: Colors.indigo),
                    SizedBox(height: 16),
                    SkeletonLoader.kpiCard(icon: Icons.shopping_bag, color: Colors.purple),
                  ],
                )
              : Column(
                  children: [
                    _buildInventorySummaryCard(),
                    SizedBox(height: 16),
                    _buildMovementHealthCard(),
                    SizedBox(height: 16),
                    _buildHoldingCard(),
                  ],
                ),
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
              const Spacer(),
              GestureDetector(
                onTap: _showMovementHealthModal,
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFastMovingItems(),
            builder: (context, snapshot) {
              final fastMoving = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.north_east, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fast Moving (${fastMoving.length})',
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
                    '${item['saleCount']}x sold',
                    Colors.green[600]!,
                    () => _navigateToInventoryDetail(item),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getSlowMovingItems(),
            builder: (context, snapshot) {
              final slowMoving = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Slow Moving (${slowMoving.length})',
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
                    '${item['daysInStock']}d old',
                    Colors.orange[600]!,
                    () => _navigateToInventoryDetail(item),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showMovementHealthModal() async {
    final fastMoving = await _getFastMovingItems();
    final slowMoving = await _getSlowMovingItems();
    
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
        child: DefaultTabController(
          length: 2,
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
                    const Expanded(
                      child: Text(
                        'Movement Health Analysis',
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
              TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.green,
                tabs: [
                  Tab(text: 'Fast Moving (${fastMoving.length})'),
                  Tab(text: 'Slow Moving (${slowMoving.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMovementList(fastMoving, true),
                    _buildMovementList(slowMoving, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMovementList(List<Map<String, dynamic>> items, bool isFastMoving) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = isFastMoving ? Colors.green : Colors.orange;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (isFastMoving) ...[
                Text(
                  'Sales: ${item['saleCount']} times (${item['totalSold']} units)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  'Turnover: ${item['turnoverRate'].toStringAsFixed(1)}x per week',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
                ),
              ] else ...[
                Text(
                  'Stock: ${item['currentStock']} units • Sales: ${item['totalSold']} units',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  item['lastSoldDate'] != null 
                      ? 'Last sold: ${item['daysInStock']} days ago'
                      : 'Never sold in last 30 days',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  

  
  Future<List<Map<String, dynamic>>> _getFastMovingItems() async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      final inventoryService = InventoryService();
      final allItems = await inventoryService.getAllItems();
      
      // Calculate sales in last 30 days for each item
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));
      
      Map<String, Map<String, dynamic>> itemSales = {};
      
      // Analyze sales invoices from last 30 days
      for (final invoice in allInvoices) {
        if (invoice.invoiceType == 'sales' && 
            invoice.date.isAfter(thirtyDaysAgo) &&
            invoice.status != 'cancelled') {
          
          for (final item in invoice.items) {
            final itemName = item.name;
            if (!itemSales.containsKey(itemName)) {
              itemSales[itemName] = {
                'totalSold': 0,
                'saleCount': 0,
                'lastSoldDate': invoice.date,
              };
            }
            
            itemSales[itemName]!['totalSold'] += item.quantity;
            itemSales[itemName]!['saleCount'] += 1;
            
            // Update last sold date if this is more recent
            if (invoice.date.isAfter(itemSales[itemName]!['lastSoldDate'])) {
              itemSales[itemName]!['lastSoldDate'] = invoice.date;
            }
          }
        }
      }
      
      // Define fast moving threshold: >2 sales OR >10 units sold in 30 days
      List<Map<String, dynamic>> fastMoving = [];
      
      for (final entry in itemSales.entries) {
        final itemName = entry.key;
        final salesData = entry.value;
        final saleCount = salesData['saleCount'] as int;
        final totalSold = salesData['totalSold'] as int;
        
        if (saleCount >= 2 || totalSold >= 10) {
          // Calculate turnover rate (sales per week)
          final turnoverRate = (saleCount / 4.3).toDouble(); // 30 days ≈ 4.3 weeks
          
          fastMoving.add({
            'name': itemName,
            'turnoverRate': turnoverRate,
            'saleCount': saleCount,
            'totalSold': totalSold,
            'lastSoldDate': salesData['lastSoldDate'],
            'id': itemName.toLowerCase().replaceAll(' ', '_'),
          });
        }
      }
      
      // Sort by turnover rate descending
      fastMoving.sort((a, b) => (b['turnoverRate'] as double).compareTo(a['turnoverRate'] as double));
      
      return fastMoving;
    } catch (e) {
      print('Error calculating fast moving items: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _getSlowMovingItems() async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      final inventoryService = InventoryService();
      final allItems = await inventoryService.getAllItems();
      
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));
      
      // Get all items that have current stock
      Map<String, Map<String, dynamic>> itemData = {};
      
      for (final item in allItems) {
        if (item.currentStock > 0) {
          itemData[item.name] = {
            'currentStock': item.currentStock,
            'lastUpdated': item.lastUpdated,
            'totalSold': 0,
            'saleCount': 0,
            'lastSoldDate': null,
          };
        }
      }
      
      // Calculate recent sales for items with stock
      for (final invoice in allInvoices) {
        if (invoice.invoiceType == 'sales' && 
            invoice.date.isAfter(thirtyDaysAgo) &&
            invoice.status != 'cancelled') {
          
          for (final item in invoice.items) {
            final itemName = item.name;
            if (itemData.containsKey(itemName)) {
              itemData[itemName]!['totalSold'] += item.quantity;
              itemData[itemName]!['saleCount'] += 1;
              
              if (itemData[itemName]!['lastSoldDate'] == null ||
                  invoice.date.isAfter(itemData[itemName]!['lastSoldDate'])) {
                itemData[itemName]!['lastSoldDate'] = invoice.date;
              }
            }
          }
        }
      }
      
      // Define slow moving: <2 sales AND <10 units sold in 30 days
      List<Map<String, dynamic>> slowMoving = [];
      
      for (final entry in itemData.entries) {
        final itemName = entry.key;
        final data = entry.value;
        final saleCount = data['saleCount'] as int;
        final totalSold = data['totalSold'] as int;
        
        if (saleCount < 2 && totalSold < 10) {
          final lastSoldDate = data['lastSoldDate'] as DateTime?;
          final daysInStock = lastSoldDate != null 
              ? now.difference(lastSoldDate).inDays
              : now.difference(data['lastUpdated'] as DateTime).inDays;
          
          slowMoving.add({
            'name': itemName,
            'currentStock': data['currentStock'],
            'saleCount': saleCount,
            'totalSold': totalSold,
            'daysInStock': daysInStock,
            'lastSoldDate': lastSoldDate,
            'id': itemName.toLowerCase().replaceAll(' ', '_'),
          });
        }
      }
      
      // Sort by days in stock descending (oldest first)
      slowMoving.sort((a, b) => (b['daysInStock'] as int).compareTo(a['daysInStock'] as int));
      
      return slowMoving;
    } catch (e) {
      print('Error calculating slow moving items: $e');
      return [];
    }
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
  Future<void> _sendReminder(Map<String, dynamic> customer) async {
    try {
      // Get customer details including phone number
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      // Get the total due amount
      final totalDue = customer['amount'] as double? ?? 0.0;

      // Create WhatsApp message
      final message = '''Hello ${customer['name']},

This is a friendly reminder regarding your outstanding balance.

Total Due: ₹${totalDue.toStringAsFixed(2)}

Please arrange for the payment at your earliest convenience.

Thank you for your business!

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }

      // Add India country code if it's a 10-digit number starting with 6-9
      if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
        phoneNumber = '91$phoneNumber';
      }

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      final whatsappUri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening WhatsApp for ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp. Please install WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reminder: ${e.toString()}')),
      );
    }
  }

  Future<void> _callCustomer(Map<String, dynamic> customer) async {
    try {
      // Get customer details including phone number
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      // Create tel: URL
      final telUrl = 'tel:$phoneNumber';
      final telUri = Uri.parse(telUrl);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calling customer: ${e.toString()}')),
      );
    }
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
          _isLoading
              ? SkeletonLoader.dueReminderCard()
              : _buildDueRemindersCard(),
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
  
  Future<Map<String, dynamic>> _getOutstandingPaymentsData(String dateRange) async {
    try {
      final customerService = CustomerService.instance;
      final fs = FirestoreService.instance;

      // Calculate start date from date range
      DateTime startDate;
      switch (dateRange) {
        case 'Today':
          final now = DateTime.now();
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Last 7 days':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Last 30 days':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'Last 90 days':
          startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case 'This year':
          final now = DateTime.now();
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(2000, 1, 1); // All time
      }

      // Get all invoices with outstanding amounts, filtered by date range
      final allInvoices = await fs.getAllInvoices();
      final outstandingInvoices = allInvoices.where((inv) =>
        inv.invoiceType == 'sales' &&
        inv.remainingAmount > 0 &&
        inv.date.isAfter(startDate.subtract(const Duration(days: 1)))
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
  
  void _showCustomerDetail(Map<String, dynamic> customer) async {
    // Get actual unpaid invoices for this customer
    final unpaidInvoices = await _getUnpaidInvoicesForCustomer(customer['name']);
    
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
                          'Total Due: ${widget.formatCurrency(customer['amount'])} • ${unpaidInvoices.length} invoices',
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
                    Expanded(
                      child: ListView.builder(
                        itemCount: unpaidInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = unpaidInvoices[index];
                          return _buildInvoiceItem(
                            invoice['invoiceNumber'],
                            invoice['date'],
                            invoice['remainingAmount'],
                          );
                        },
                      ),
                    ),
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
  
  Future<List<Map<String, dynamic>>> _getUnpaidInvoicesForCustomer(String customerName) async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      
      // Filter for unpaid sales invoices for this specific customer
      final unpaidInvoices = allInvoices.where((invoice) => 
        invoice.invoiceType == 'sales' && 
        invoice.clientName == customerName &&
        invoice.remainingAmount > 0
      ).toList();
      
      // Convert to map format for display
      return unpaidInvoices.map((invoice) => {
        'invoiceNumber': invoice.invoiceNumber,
        'date': invoice.date.toIso8601String().split('T')[0],
        'remainingAmount': invoice.remainingAmount,
        'total': invoice.total,
        'amountPaid': invoice.amountPaid,
      }).toList();
    } catch (e) {
      print('Error getting unpaid invoices for customer: $e');
      return [];
    }
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
  
  Future<void> _sendReminder(Map<String, dynamic> customer) async {
    try {
      // Get customer details including phone number
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      // Get the total due amount
      final totalDue = customer['amount'] as double? ?? 0.0;

      // Create WhatsApp message
      final message = '''Hello ${customer['name']},

This is a friendly reminder regarding your outstanding balance.

Total Due: ₹${totalDue.toStringAsFixed(2)}

Please arrange for the payment at your earliest convenience.

Thank you for your business!

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }

      // Add India country code if it's a 10-digit number starting with 6-9
      if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
        phoneNumber = '91$phoneNumber';
      }

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      final whatsappUri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening WhatsApp for ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp. Please install WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reminder: ${e.toString()}')),
      );
    }
  }

  Future<void> _callCustomer(Map<String, dynamic> customer) async {
    try {
      // Get customer details including phone number
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      // Create tel: URL
      final telUrl = 'tel:$phoneNumber';
      final telUri = Uri.parse(telUrl);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calling customer: ${e.toString()}')),
      );
    }
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
  
  void _showItemDetail(Map<String, dynamic> item) async {
    final customersForItem = await _getCustomersForItem(item['name']);
    
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
                          'Total Due: ${widget.formatCurrency(item['amount'])} • ${customersForItem.length} customers',
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
                  final daysOverdue = _calculateDaysOverdueFromDueDate(customerDebt['dueDate']);
                  
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
  
  int _calculateDaysOverdueFromDueDate(String dueDateString) {
    try {
      final dueDate = DateTime.parse(dueDateString);
      final now = DateTime.now();
      final daysDiff = now.difference(dueDate).inDays;
      return daysDiff > 0 ? daysDiff : 0; // Only positive overdue days
    } catch (e) {
      return 0;
    }
  }
  
  Future<List<Map<String, dynamic>>> _getCustomersForItem(String itemName) async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      
      List<Map<String, dynamic>> customersForItem = [];
      
      // Find all unpaid sales invoices that contain this item
      for (final invoice in allInvoices) {
        if (invoice.invoiceType == 'sales' && invoice.remainingAmount > 0) {
          // Check if this invoice contains the specified item
          for (final item in invoice.items) {
            if (item.name == itemName) {
              // Calculate item's share of the outstanding amount
              final invoiceLineItemsTotal = invoice.items.fold<double>(0.0, 
                (sum, lineItem) => sum + (lineItem.price * lineItem.quantity));
              
              if (invoiceLineItemsTotal > 0) {
                final itemLineTotal = item.price * item.quantity;
                final outstandingPercentage = invoice.remainingAmount / invoiceLineItemsTotal;
                final itemOutstandingAmount = itemLineTotal * outstandingPercentage;
                
                if (itemOutstandingAmount > 0) {
                  customersForItem.add({
                    'customerName': invoice.clientName,
                    'amount': itemOutstandingAmount,
                    'invoiceNo': invoice.invoiceNumber,
                    'invoiceDate': invoice.date.toIso8601String().split('T')[0],
                    'dueDate': invoice.date.toIso8601String().split('T')[0],
                  });
                }
              }
              break; // Found the item in this invoice, no need to check other items
            }
          }
        }
      }
      
      // Sort by amount descending
      customersForItem.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      
      return customersForItem;
    } catch (e) {
      print('Error getting customers for item: $e');
      return [];
    }
  }
}
