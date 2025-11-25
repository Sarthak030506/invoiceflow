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
import 'sections/overview_kpis_section.dart';
import 'sections/revenue_analytics_section.dart';
import 'sections/items_insights_section.dart';
import 'sections/inventory_analytics_section.dart';
import 'sections/due_reminders_section.dart';
import 'sections/charts_section.dart';

class AnalyticsRedesignScaffold extends StatefulWidget {
  final String? initialSection;
  final String? selectedDateRange;
  final Map<String, DateTime>? customDateRange;
  
  final AnalyticsService? analyticsService;
  final InventoryService? inventoryService;
  final FirestoreService? firestoreService;
  
  const AnalyticsRedesignScaffold({
    Key? key,
    this.initialSection,
    this.selectedDateRange,
    this.customDateRange,
    this.analyticsService,
    this.inventoryService,
    this.firestoreService,
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
          OverviewKpisSection(
            isLoading: _isLoading,
            chartData: chartData,
            performanceInsights: performanceInsights,
          ),
          SizedBox(height: 16),
          RevenueAnalyticsSection(
            isLoading: _isLoading,
            selectedDateRange: selectedDateRange,
            chartData: chartData,
            customerAnalyticsData: customerAnalyticsData,
            inventoryAnalytics: inventoryAnalytics,
            inventoryService: widget.inventoryService,
          ),
          SizedBox(height: 16),
          ItemsInsightsSection(
            isLoading: _isLoading,
            performanceInsights: performanceInsights,
          ),
          SizedBox(height: 16),
          InventoryAnalyticsSection(
            isLoading: _isLoading,
            inventoryAnalytics: inventoryAnalytics,
            inventoryService: widget.inventoryService,
            firestoreService: widget.firestoreService,
          ),
          SizedBox(height: 16),
          DueRemindersSection(
            isLoading: _isLoading,
            outstandingPayments: outstandingPayments,
          ),
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
          child: OverviewKpisSection(
            isLoading: _isLoading,
            chartData: chartData,
            performanceInsights: performanceInsights,
          ),
        );
      case 'revenue':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: RevenueAnalyticsSection(
            isLoading: _isLoading,
            selectedDateRange: selectedDateRange,
            chartData: chartData,
            customerAnalyticsData: customerAnalyticsData,
            inventoryAnalytics: inventoryAnalytics,
            inventoryService: widget.inventoryService,
          ),
        );
      case 'items':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: ItemsInsightsSection(
            isLoading: _isLoading,
            performanceInsights: performanceInsights,
          ),
        );
      case 'inventory':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: InventoryAnalyticsSection(
            isLoading: _isLoading,
            inventoryAnalytics: inventoryAnalytics,
            inventoryService: widget.inventoryService,
          ),
        );
      case 'due':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: DueRemindersSection(
            isLoading: _isLoading,
            outstandingPayments: outstandingPayments,
          ),
        );
      case 'table':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: _buildAnalyticsTableCard(),
        );
      case 'charts':
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: ChartsSection(
            isLoading: _isLoading,
            chartData: chartData,
            inventoryAnalytics: inventoryAnalytics,
          ),
        );
      default:
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: OverviewKpisSection(
            isLoading: _isLoading,
            chartData: chartData,
            performanceInsights: performanceInsights,
          ),
        );
    }
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
      
      // Use injected services or default to actual instances
      final analyticsService = widget.analyticsService ?? AnalyticsService();
      final inventoryService = widget.inventoryService ?? InventoryService();

      final results = await Future.wait([
        analyticsService.getFilteredAnalytics(serviceRange),
        analyticsService.getCustomerWiseRevenue(serviceRange),
        analyticsService.fetchPerformanceInsights(serviceRange),
        analyticsService.getChartAnalytics(serviceRange),
        inventoryService.getInventoryAnalytics(),
      ]);

      setState(() {
        analyticsData = results[0] as List<Map<String, dynamic>>;
        customerAnalyticsData = results[1] as List<Map<String, dynamic>>;
        performanceInsights = results[2] as Map<String, dynamic>;
        chartData = results[3] as Map<String, dynamic>;
        inventoryAnalytics = results[4] as Map<String, dynamic>;
        outstandingPayments = {}; // Initialize to empty map
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
            title: const Text(
              'Analytics Table',
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
  

}

