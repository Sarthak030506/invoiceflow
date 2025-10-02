import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';
import '../../services/analytics_service.dart';
import '../../services/inventory_service.dart';
import './widgets/analytics_charts_widget.dart'
    if (dart.library.html) './widgets/analytics_charts_widget_web.dart';
import './widgets/analytics_table_widget.dart';
import './widgets/date_range_picker_widget.dart';
import './widgets/export_button_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 2; // Analytics tab index
  String _selectedDateRange = 'All time';
  String _searchQuery = '';
  String _sortColumn = 'revenue'; // Changed default sort to revenue
  bool _sortAscending = false; // Changed to show highest revenue first
  bool _isLoading = false;
  String _errorMessage = '';

  final AnalyticsService _analyticsService = AnalyticsService();

  // Analytics data from CSV
  List<Map<String, dynamic>> _analyticsData = [];
  Map<String, dynamic> _performanceInsights = {};
  Map<String, dynamic> _chartData = {};
  Map<String, dynamic> _inventoryAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Added third tab for insights
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads analytics data from CSV
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get analytics data
      final inventoryService = InventoryService();
      final results = await Future.wait([
        _analyticsService.getFilteredAnalytics(_selectedDateRange),
        _analyticsService.fetchPerformanceInsights(_selectedDateRange),
        _analyticsService.getChartAnalytics(_selectedDateRange),
        inventoryService.getInventoryAnalytics(),
      ]);

      setState(() {
        _analyticsData = results[0] as List<Map<String, dynamic>>;
        _performanceInsights = results[1] as Map<String, dynamic>;
        _chartData = results[2] as Map<String, dynamic>;
        _inventoryAnalytics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = _analyticsData;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) => (item['itemName'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sorting with null-safe logic
    filtered.sort((a, b) {
      final aValue = a[_sortColumn];
      final bValue = b[_sortColumn];

      // Add null-checking logic
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return -1;
      if (bValue == null) return 1;

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/invoices-list-screen');
        break;
      case 2:
        // Current screen - Analytics
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/customers-screen');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }

  void _onDateRangeChanged(String range) {
    setState(() {
      _selectedDateRange = range;
    });
    _loadAnalyticsData();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onSortChanged(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false; // Default to descending for numerical columns
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          ExportButtonWidget(
            onExport: () {
              // Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export functionality coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12.h),
          child: Column(
            children: [
              // Date Range Picker
              DateRangePickerWidget(
                selectedRange: _selectedDateRange,
                onRangeChanged: _onDateRangeChanged,
              ),
              SizedBox(height: 1.h),
              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.8),
                  labelStyle: theme.textTheme.labelLarge,
                  unselectedLabelStyle: theme.textTheme.labelMedium,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'table_chart',
                            size: 18,
                            color: _tabController.index == 0
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          SizedBox(width: 1.w),
                          Text('Table'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'bar_chart',
                            size: 18,
                            color: _tabController.index == 1
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          SizedBox(width: 1.w),
                          Text('Charts'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'insights',
                            size: 18,
                            color: _tabController.index == 2
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          SizedBox(width: 1.w),
                          Text('Insights'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading analytics data...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorState(theme)
              : _filteredData.isEmpty && _analyticsData.isEmpty
                  ? _buildEmptyState(theme)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Table View
                        AnalyticsTableWidget(
                          data: _filteredData,
                          searchQuery: _searchQuery,
                          sortColumn: _sortColumn,
                          sortAscending: _sortAscending,
                          onSearchChanged: _onSearchChanged,
                          onSortChanged: _onSortChanged,
                        ),
                        // Charts View
                        AnalyticsChartsWidget(
                          data: _chartData,
                          insights: _performanceInsights,
                        ),
                        // Insights View
                        _buildInsightsView(theme),
                      ],
                    ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: 2,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              size: 80,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 3.h),
            Text(
              'Error Loading Analytics',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadAnalyticsData,
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text('Retry'),
              style: theme.elevatedButtonTheme.style?.copyWith(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'analytics',
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Analytics Data',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'No invoice data found in the Google Sheets. Please check your spreadsheet and ensure it contains invoice data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/invoices-list-screen');
              },
              icon: CustomIconWidget(
                iconName: 'add',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text('View Invoices'),
              style: theme.elevatedButtonTheme.style?.copyWith(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsView(ThemeData theme) {
    if (_performanceInsights.isEmpty) {
      return Center(
        child: Text(
          'No insights available',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final insights = _performanceInsights['insights'] as Map<String, dynamic>;
    final trends = _performanceInsights['trends'] as Map<String, dynamic>;
    final topRevenueItems =
        _performanceInsights['topRevenueItems'] as List<dynamic>;
    final topClients = _performanceInsights['topClients'] as List<dynamic>;
    final categoryPerformance =
        _performanceInsights['categoryPerformance'] as Map<String, dynamic>;
    final invoiceTypeBreakdown = 
        _performanceInsights['invoiceTypeBreakdown'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Type Breakdown
          if (invoiceTypeBreakdown != null) ...[  
            Text(
              'Invoice Type Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Sales Invoices',
                    '${invoiceTypeBreakdown['salesCount']}',
                    'shopping_cart_outlined',
                    null,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Purchase Invoices',
                    '${invoiceTypeBreakdown['purchaseCount']}',
                    'inventory_outlined',
                    null,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Sales Revenue',
                    '₹${(invoiceTypeBreakdown['salesRevenue'] as double).toStringAsFixed(2)}',
                    'attach_money',
                    null,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Purchase Expense',
                    '₹${(invoiceTypeBreakdown['purchaseRevenue'] as double).toStringAsFixed(2)}',
                    'money_off',
                    null,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          
          // Key Metrics
          Text(
            'Key Metrics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Total Items',
                  insights['totalUniqueItems'].toString(),
                  'inventory',
                  null,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Categories',
                  insights['totalCategories'].toString(),
                  'category',
                  null,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Total Clients',
                  insights['totalClients'].toString(),
                  'people',
                  null,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Avg Revenue/Item',
                  '₹${(insights['averageRevenuePerItem'] as double).toStringAsFixed(2)}',
                  'attach_money',
                  null,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Trends
          Text(
            'Trends (Last 30 Days)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Revenue Change',
                  '${(trends['revenueChange'] as double).toStringAsFixed(1)}%',
                  'trending_up',
                  trends['revenueChange'] as double,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Items Sold Change',
                  '${(trends['itemsSoldChange'] as double).toStringAsFixed(1)}%',
                  'trending_up',
                  trends['itemsSoldChange'] as double,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Top Revenue Items
          if (topRevenueItems.isNotEmpty) ...[
            Text(
              'Top Revenue Items',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: topRevenueItems.length,
              itemBuilder: (context, index) {
                final item = topRevenueItems[index] as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.only(bottom: 1.h),
                  elevation: theme.cardTheme.elevation,
                  shape: theme.cardTheme.shape,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item['itemName'] as String,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Quantity: ${item['quantitySold']} • Category: ${item['category']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '₹${(item['revenue'] as double).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 4.h),
          ],

          // Top Clients
          if (topClients.isNotEmpty) ...[
            Text(
              'Top Clients',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: topClients.length,
              itemBuilder: (context, index) {
                final client = topClients[index] as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.only(bottom: 1.h),
                  elevation: theme.cardTheme.elevation,
                  shape: theme.cardTheme.shape,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      client['clientName'] as String,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Invoices: ${client['invoiceCount']} • Avg: ₹${(client['averageInvoiceValue'] as double).toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '₹${(client['totalRevenue'] as double).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 4.h),
          ],

          // Category Performance
          if (categoryPerformance.isNotEmpty) ...[
            Text(
              'Category Performance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: categoryPerformance.length,
              itemBuilder: (context, index) {
                final entry = categoryPerformance.entries.elementAt(index);
                final category = entry.key;
                final data = entry.value as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.only(bottom: 1.h),
                  elevation: theme.cardTheme.elevation,
                  shape: theme.cardTheme.shape,
                  child: ListTile(
                    leading: CustomIconWidget(
                      iconName: 'category',
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      category,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Items: ${data['itemCount']} • Qty: ${data['totalQuantity']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '₹${(data['totalRevenue'] as double).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 4.h),
          ],

          // Inventory Analytics
          if (_inventoryAnalytics.isNotEmpty) ...[
            Text(
              'Inventory Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Total Items',
                    '${_inventoryAnalytics['totalItems']}',
                    'inventory_2',
                    null,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Inventory Value',
                    '₹${(_inventoryAnalytics['totalValue'] as double).toStringAsFixed(0)}',
                    'account_balance_wallet',
                    null,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Low Stock Items',
                    '${_inventoryAnalytics['lowStockCount']}',
                    'warning_amber',
                    null,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Avg Stock Value',
                    '₹${(_inventoryAnalytics['averageStockValue'] as double).toStringAsFixed(0)}',
                    'trending_up',
                    null,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            
            // Fast Moving Items
            if ((_inventoryAnalytics['fastMovingItems'] as List).isNotEmpty) ...[
              Text(
                'Fast Moving Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: (_inventoryAnalytics['fastMovingItems'] as List).length,
                itemBuilder: (context, index) {
                  final itemData = (_inventoryAnalytics['fastMovingItems'] as List)[index];
                  final item = itemData['item'];
                  final turnoverRate = itemData['turnoverRate'] as double;
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 1.h),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.trending_up, color: Colors.green.shade600),
                      ),
                      title: Text(item.name),
                      subtitle: Text('Turnover: ${(turnoverRate * 100).toStringAsFixed(1)}%'),
                      trailing: Text(
                        '${item.currentStock.toInt()} left',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 3.h),
            ],
            
            // Slow Moving Items
            if ((_inventoryAnalytics['slowMovingItems'] as List).isNotEmpty) ...[
              Text(
                'Slow Moving Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: ((_inventoryAnalytics['slowMovingItems'] as List).length).clamp(0, 5),
                itemBuilder: (context, index) {
                  final item = (_inventoryAnalytics['slowMovingItems'] as List)[index];
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 1.h),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.trending_down, color: Colors.red.shade600),
                      ),
                      title: Text(item.name),
                      subtitle: Text('Last updated: ${_formatInventoryDate(item.lastUpdated)}'),
                      trailing: Text(
                        '${item.currentStock.toInt()} stock',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatInventoryDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String title,
    String value,
    String iconName,
    double? changeValue,
    [Color? customColor]
  ) {
    Color? changeColor;
    if (changeValue != null) {
      changeColor = changeValue >= 0 ? Colors.green : Colors.red;
    }

    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomIconWidget(
                  iconName: iconName,
                  size: 24,
                  color: customColor ?? theme.colorScheme.primary,
                ),
                if (changeValue != null)
                  Icon(
                    changeValue >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: changeColor,
                    size: 20,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: changeColor ?? customColor,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}