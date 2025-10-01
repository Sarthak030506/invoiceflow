import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';

import '../../providers/auth_provider.dart';
import '../invoice_type_selection_screen.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../services/csv_invoice_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_service.dart';
import '../../services/inventory_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_logger.dart';
import './widgets/metric_card_widget.dart';
import './widgets/recent_invoice_item_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../animations/fluid_animations.dart';
import 'dart:async';

class HomeDashboard extends StatefulWidget {
  final String csvPath;
  
  const HomeDashboard({
    required this.csvPath,
    Key? key,
  }) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late final CsvInvoiceService _csvInvoiceService;
  final InvoiceService _invoiceService = InvoiceService.instance;
  final EventService _eventService = EventService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _selectedIndex = 0;
  String _errorMessage = '';
  StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _csvInvoiceService = CsvInvoiceService(assetPath: widget.csvPath);
    _loadDashboardData();
    _setupEventListening();
  }

  // Colored pill for invoice type (SALES/PURCHASE)
  Widget _typeBadge(String text, Color base) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: base.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: base.withOpacity(0.35), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: base,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // High-contrast status badge (PAID/POSTED/OVERDUE etc.)
  Widget _oldStatusBadge(String raw) {
    final status = raw.toUpperCase();
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case 'PAID':
        bg = Colors.green.shade600;
        break;
      case 'POSTED':
        bg = Colors.blueGrey.shade600;
        break;
      case 'PURCHASE':
        bg = AppTheme.secondaryLight;
        break;
      case 'SALES':
        bg = AppTheme.primaryAccentLight;
        break;
      default:
        bg = Colors.orange.shade600; // for DUE/OVERDUE
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: bg.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  void _setupEventListening() {
    _eventSubscription = _eventService.eventStream.listen((event) {
      if (event == 'DashboardUpdated' || event == 'InventoryUpdated') {
        _loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // Data from CSV
  Map<String, dynamic> dashboardData = {};
  List<InvoiceModel> recentInvoices = [];
  List<InvoiceModel> allInvoices = [];
  int inStockSKUs = 0;
  int lowStockCount = 0;
  int totalUnits = 0;
  double inventoryValue = 0.0;
  List<dynamic> lowStockItems = [];
  
  // Feature flag for new inventory UI
  static const bool kNewInventoryHome = true;


  /// Loads dashboard data from CSV
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Skip debug operations for performance
      
      // Fetch dashboard metrics and invoices concurrently from CSV
      final inventoryService = InventoryService();
      final results = await Future.wait([
        _invoiceService.fetchDashboardMetrics(),
        _invoiceService.fetchRecentInvoices(),
        _invoiceService.fetchAllInvoices(),
        _getInventoryMetrics(),
      ]);
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        dashboardData = results[0] as Map<String, dynamic>;
        recentInvoices = results[1] as List<InvoiceModel>;
        allInvoices = results[2] as List<InvoiceModel>;
        final inventoryData = results[3] as Map<String, dynamic>;
        inStockSKUs = inventoryData['inStockSKUs'];
        lowStockCount = inventoryData['lowStockCount'];
        totalUnits = inventoryData['totalUnits'];
        inventoryValue = inventoryData['inventoryValue'];
        lowStockItems = inventoryData['lowStockItems'];
        _isLoading = false;
      });

      // Skip connection validation for faster loading
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Validates CSV connection and shows status
  Future<void> _validateConnection() async {
    try {
      final isConnected = await _invoiceService.validateGoogleSheetsConnection();
      if (mounted) {
        if (!isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('CSV data unavailable'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Loaded data from Local Database'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Connection validation error', 'HomeDashboard', e);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully from Local Database'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) return; // Already on home
    
    // Navigate immediately without setState
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.invoicesListScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.analyticsScreen);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.customersScreen);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profileScreen);
        break;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Get the height after the widget is built
    final height = SizerUtil.height;

    return AdaptiveScaffold(
      currentIndex: _selectedIndex,
      onNavigationChanged: _onBottomNavTap,
      items: const [
        NavigationItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Invoices',
        ),
        NavigationItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        NavigationItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Customers',
        ),
        NavigationItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppTheme.getPrimaryGradient(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'InvoiceFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.assignment_return, color: Colors.orange.shade600),
              title: Text(
                'Returns',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text('Manage sales & purchase returns'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/returns-screen');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.inventory_2, color: Colors.blue.shade600),
              title: Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventory-screen');
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_basket, color: Colors.purple.shade600),
              title: Text(
                'Manage Item Rates',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text('Edit prices for all items'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/items-screen');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey.shade600),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profileScreen);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(isDark),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_getGreeting()}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'InvoiceFlow',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 6.w,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? Container(
                      height: 50.h,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading invoice data...'),
                          ],
                        ),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Container(
                          height: 40.h,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'error_outline',
                                  color: Theme.of(context).colorScheme.error,
                                  size: 15.w,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Error Loading Data',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                SizedBox(height: 1.h),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                PrimaryButton(
                                  text: 'Retry',
                                  onPressed: _loadDashboardData,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pending Follow-ups Section
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3.w),
                              child: _buildPendingFollowupsSection(),
                            ),

                            SizedBox(height: 4.h),

                            // Recent Recipients Section
                            _buildRecentRecipientsSection(),           

                            SizedBox(height: 4.h),

                            // Inventory Summary Card
                            _buildInventorySummaryCard(),

                            SizedBox(height: 4.h),

                            _buildRecentInvoicesSection(recentInvoices),

                            SizedBox(height: 2.h),

                            // Data Source Info
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Source: Local Database',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'Last updated: ${dashboardData["lastUpdated"] != null ? _formatLastUpdated(dashboardData["lastUpdated"]) : 'Unknown'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: FloatingActionButton.extended(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10.w,
                              height: 0.5.h,
                              margin: EdgeInsets.only(top: 2.h, bottom: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                              title: Text('Create Invoice'),
                              subtitle: Text('Add new sales or purchase invoice'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push<InvoiceModel>(
                                  MaterialPageRoute<InvoiceModel>(
                                    builder: (context) => const InvoiceTypeSelectionScreen(),
                                  ),
                                ).then((newInvoice) async {
                                  if (newInvoice != null && newInvoice is InvoiceModel) {
                                    setState(() {
                                      recentInvoices.insert(0, newInvoice);
                                    });
                                    await _invoiceService.addInvoice(newInvoice);
                                    await _loadDashboardData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${newInvoice.invoiceType.substring(0, 1).toUpperCase()}${newInvoice.invoiceType.substring(1)} invoice added!')),
                                    );
                                  }
                                });
                              },
                            ),
                            SizedBox(height: 2.h),
                          ],
                        ),
                      );
                    },
                  );
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.add_rounded,
                      size: 6.w,
                      color: Colors.white,
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Track which tab is selected in the Pending Follow-ups section
  int _selectedFollowUpTab = 0; // 0 = Customer Dues, 1 = Your Dues

  Widget _buildPendingFollowupsSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter customer pending invoices (sales invoices)
    final pendingCustomerInvoices = allInvoices
        .where((invoice) => 
            invoice.invoiceType == 'sales' && 
            invoice.status.toLowerCase() != 'paid' &&
            invoice.paymentStatus == PaymentStatus.balanceDue &&
            (invoice.followUpDate == null || 
             DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isBefore(today) ||
             DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isAtSameMomentAs(today)))
        .toList();
    
    // Filter shopkeeper's own pending invoices (purchase invoices)
    final pendingPurchaseInvoices = allInvoices
        .where((invoice) => 
            invoice.invoiceType == 'purchase' && 
            invoice.status.toLowerCase() != 'paid' &&
            invoice.paymentStatus == PaymentStatus.balanceDue)
        .toList();
    
    // Sort customer invoices by remaining amount (highest first) and date (oldest first)
    pendingCustomerInvoices.sort((a, b) {
      final amountComparison = b.absoluteRemainingAmount.compareTo(a.absoluteRemainingAmount);
      if (amountComparison != 0) return amountComparison;
      return a.date.compareTo(b.date);
    });
    
    // Sort purchase invoices by remaining amount (highest first) and date (oldest first)
    pendingPurchaseInvoices.sort((a, b) {
      final amountComparison = b.absoluteRemainingAmount.compareTo(a.absoluteRemainingAmount);
      if (amountComparison != 0) return amountComparison;
      return a.date.compareTo(b.date);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add vertical spacing above the section
        SizedBox(height: 3.h),
        
        // Section header - moved outside the card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  gradient: AppTheme.getPrimaryGradient(!isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Follow-ups',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Payment reminders & overdue invoices',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Tab selector for Customer Dues vs Your Dues - moved outside the card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Customer Dues Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFollowUpTab = 0;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _selectedFollowUpTab == 0 
                            ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Customer Dues',
                          style: TextStyle(
                            color: _selectedFollowUpTab == 0 
                                ? Colors.white 
                                : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Your Dues Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFollowUpTab = 1;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _selectedFollowUpTab == 1 
                            ? const Color(0xFFE3F0FF) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Your Dues',
                          style: TextStyle(
                            color: _selectedFollowUpTab == 1 
                                ? const Color(0xFF263238) 
                                : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 1.5.h),
        
        // All Caught Up Badge or Pending Payments Card (without outer card wrapper)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: _selectedFollowUpTab == 0
            // Customer Dues Tab Content
            ? (pendingCustomerInvoices.isEmpty
                ? _buildAllCaughtUpBadge('No unpaid customer invoices. All clear!')
                : _buildPendingPaymentsCard(pendingCustomerInvoices, isCustomerDues: true))
            // Your Dues Tab Content
            : (pendingPurchaseInvoices.isEmpty
                ? _buildAllCaughtUpBadge('No unpaid purchase invoices. All clear!')
                : _buildPendingPaymentsCard(pendingPurchaseInvoices, isCustomerDues: false)),
        ),
      ],
    );
  }
  
  Widget _buildAllCaughtUpBadge([String? customMessage]) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle, color: Colors.white, size: 6.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up! ✨',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    customMessage ?? 'No pending payments to review',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingPaymentsCard(List<InvoiceModel> pendingInvoices, {bool isCustomerDues = true}) {
    final totalPending = pendingInvoices.fold<double>(
      0.0, (sum, invoice) => sum + invoice.remainingAmount);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isCustomerDues 
              ? [AppTheme.primaryAccentLight, AppTheme.primaryLight]
              : [const Color(0xFFE3F0FF), const Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isCustomerDues 
              ? AppTheme.primaryAccentLight.withOpacity(0.3)
              : const Color(0xFF263238).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCustomerDues 
                ? AppTheme.primaryAccentLight.withOpacity(0.15)
                : const Color(0xFF263238).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isCustomerDues 
                        ? Colors.white.withOpacity(0.25)
                        : const Color(0xFF263238).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCustomerDues ? Icons.access_time_rounded : Icons.shopping_bag_outlined,
                    color: isCustomerDues ? Colors.white : const Color(0xFF263238),
                    size: 8.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCustomerDues 
                            ? '${pendingInvoices.length} Customer Invoice${pendingInvoices.length > 1 ? 's' : ''} Need Action'
                            : '${pendingInvoices.length} Purchase Invoice${pendingInvoices.length > 1 ? 's' : ''} Need Payment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isCustomerDues ? Colors.white : const Color(0xFF263238),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Total: ₹${_formatCurrency(totalPending)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isCustomerDues ? Colors.white.withOpacity(0.9) : const Color(0xFF263238).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Animated Invoice List
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
            child: Column(
              children: [
                ...pendingInvoices.take(3).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final invoice = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      // Ensure opacity is within valid range (0.0 to 1.0)
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - safeOpacity)),
                        child: Opacity(
                          opacity: safeOpacity,
                          child: _buildEnhancedPendingItem(invoice, isCustomerDues: isCustomerDues),
                        ),
                      );
                    },
                  );
                }),
                
                if (pendingInvoices.length > 3)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 3.h),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/invoices-list-screen'),
                      child: Text(
                        'View All ${pendingInvoices.length} Invoices',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedPendingItem(InvoiceModel invoice, {bool isCustomerDues = true}) {
    final isOverdue = invoice.followUpDate != null && 
        invoice.followUpDate!.isBefore(DateTime.now().subtract(Duration(days: 1)));
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: isCustomerDues
            ? (isOverdue ? AppTheme.errorLight.withOpacity(0.1) : AppTheme.primaryAccentLight.withOpacity(0.1))
            : const Color(0xFF263238).withOpacity(0.1),
        child: Icon(
          isCustomerDues
              ? (isOverdue ? Icons.schedule_outlined : Icons.access_time_rounded)
              : Icons.shopping_bag_outlined,
          color: isCustomerDues
              ? (isOverdue ? AppTheme.errorLight : AppTheme.primaryAccentLight)
              : const Color(0xFF263238),
          size: 6.w,
        ),
      ),
      title: Text(
        isCustomerDues ? invoice.clientName : (invoice.invoiceType == 'purchase' ? 'Supplier' : invoice.clientName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isCustomerDues ? null : const Color(0xFF263238),
        ),
      ),
      subtitle: Text(
        'Invoice #${invoice.invoiceNumber}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isCustomerDues ? AppTheme.textSecondaryLight : const Color(0xFF263238).withOpacity(0.7),
        ),
      ),
      trailing: Text(
        '₹${_formatCurrency(invoice.remainingAmount)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isCustomerDues
              ? (isOverdue ? AppTheme.errorLight : AppTheme.accentGoldLight)
              : const Color(0xFF263238),
        ),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        '/invoice-detail-screen',
        arguments: invoice,
      ),
    );
  }

  Widget _buildPendingInvoiceItem(InvoiceModel invoice) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/invoice-detail-screen',
          arguments: invoice,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Customer avatar
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    invoice.clientName.isNotEmpty ? invoice.clientName[0].toUpperCase() : 'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              
              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.clientName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'receipt',
                          color: Colors.grey.shade500,
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '₹${_formatCurrency(invoice.remainingAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  if (invoice.invoiceType == 'purchase')
                    InkWell(
                      onTap: () => _markAsPaid(invoice),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: Colors.green.shade600,
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Mark Paid',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _showSnoozeDialog(invoice),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'schedule',
                              color: Colors.orange.shade600,
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Snooze',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 30.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'receipt_long_outlined',
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Invoices Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'No invoice data found in local storage. Please add a new invoice.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: Theme.of(context)
                      .elevatedButtonTheme
                      .style
                      ?.foregroundColor
                      ?.resolve({}) ??
                  Colors.white,
              size: 4.w,
            ),
            label: const Text('Refresh Data'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _markAsPaid(InvoiceModel invoice) {
    // Update invoice status to paid
    setState(() {
      final index = allInvoices.indexWhere((inv) => inv.id == invoice.id);
      if (index != -1) {
        allInvoices[index] = invoice.copyWith(
          status: 'paid',
          amountPaid: invoice.total,
        );
      }
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice #${invoice.invoiceNumber} marked as paid'),
        backgroundColor: Colors.green,
      ),
    );
  }

void _showSnoozeDialog(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When should we remind you about ${invoice.clientName}\'s payment?'),
            SizedBox(height: 2.h),
            Text(
              'Amount: ₹${_formatCurrency(invoice.remainingAmount)}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _snoozeInvoice(invoice, 3),
            child: Text('3 days'),
          ),
          TextButton(
            onPressed: () => _snoozeInvoice(invoice, 7),
            child: Text('1 week'),
          ),
          TextButton(
            onPressed: () => _snoozeInvoice(invoice, 30),
            child: Text('1 month'),
          ),
        ],
      ),
    );
  }
  
  void _snoozeInvoice(InvoiceModel invoice, int days) async {
    final followUpDate = DateTime.now().add(Duration(days: days));
    
    try {
      final updatedInvoice = invoice.copyWith(
        followUpDate: followUpDate,
        updatedAt: DateTime.now(),
      );
      
      await _invoiceService.updateInvoice(updatedInvoice);
      
      Navigator.pop(context);
      
      // Refresh the dashboard
      await _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder snoozed for $days days'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error snoozing reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRecentRecipientsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: AppTheme.createSophisticatedContainer(
        isLight: !isDark,
        borderRadius: 24.0,
        includeElevation: true,
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(!isDark),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Recipients',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Quick access to frequent customers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add quick-add button
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/customers-screen');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppTheme.primaryLight,
                      size: 5.w,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Container(
              height: 12.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildRecentCustomers(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentCustomers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueCustomers = <String, InvoiceModel>{};
    final colors = [
      AppTheme.primaryLight,
      AppTheme.primaryVariantLight,
      AppTheme.primaryAccentLight,
      AppTheme.secondaryLight,
      AppTheme.secondaryVariantLight,
      AppTheme.accentGoldLight,
    ];

    // Get unique customers from recent invoices, prioritizing most recent
    for (final invoice in allInvoices.reversed) {
      if (!uniqueCustomers.containsKey(invoice.clientName) && uniqueCustomers.length < 6) {
        uniqueCustomers[invoice.clientName] = invoice;
      }
    }

    if (uniqueCustomers.isEmpty) {
      return [
        Container(
          width: 20.w,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'No recent customers',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return uniqueCustomers.entries.map((entry) {
      final index = uniqueCustomers.keys.toList().indexOf(entry.key);
      final customer = entry.value;
      final initials = customer.clientName.split(' ').map((name) => name.isNotEmpty ? name[0] : '').take(2).join();
      final chipColor = colors[index % colors.length];

      return Container(
        margin: EdgeInsets.only(right: 3.w),
        child: InkWell(
          onTap: () => _onCustomerTap(customer),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      chipColor,
                      chipColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: chipColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                customer.clientName.length > 10 ? '${customer.clientName.substring(0, 10)}...' : customer.clientName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRecentInvoicesSection(List<InvoiceModel> recentInvoices) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header - outside card
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  gradient: AppTheme.getPrimaryGradient(!isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Invoices',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Latest ${recentInvoices.length} invoices',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/invoices-list-screen'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.primaryLight,
                        size: 3.w,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.5.h),

          // Invoice cards with subtle background
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withOpacity(0.3)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: recentInvoices.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: _buildEmptyInvoiceState(isDark),
                  )
                : Container(
                    height: 20.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      itemCount: recentInvoices.length,
                      key: PageStorageKey('recent_invoices'),
                      itemBuilder: (context, index) {
                        final invoice = recentInvoices[index];
                        return _buildInvoiceCard(invoice, isDark, index == recentInvoices.length - 1);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, bool isDark, bool isLast) {
    final isSales = invoice.invoiceType.toLowerCase() == 'sales';
    final Color primaryColor = isSales ? AppTheme.primaryLight : AppTheme.secondaryLight;
    final Color accentColor = isSales ? AppTheme.primaryVariantLight : AppTheme.secondaryVariantLight;

    return Container(
      width: 75.w,
      margin: EdgeInsets.only(right: isLast ? 0 : 3.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(
          context,
          '/invoice-detail-screen',
          arguments: invoice,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.08),
                accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and status badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTypeBadge(invoice.invoiceType.toUpperCase(), primaryColor),
                    _buildStatusBadge(invoice.status),
                  ],
                ),
                SizedBox(height: 1.5.h),

                // Invoice number
                Text(
                  invoice.invoiceNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),

                // Client name
                Text(
                  invoice.clientName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Amount and navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                            fontSize: 9.sp,
                          ),
                        ),
                        Text(
                          '₹${invoice.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 4.w,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInvoiceState(bool isDark) {
    return Container(
      height: 20.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No recent invoices',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/invoice-type-selection'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Create First Invoice',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 8.sp,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'paid':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'posted':
        badgeColor = Colors.blue;
        badgeIcon = Icons.schedule;
        break;
      case 'overdue':
        badgeColor = Colors.red;
        badgeIcon = Icons.warning;
        break;
      case 'draft':
        badgeColor = Colors.grey;
        badgeIcon = Icons.edit;
        break;
      default:
        badgeColor = Colors.orange;
        badgeIcon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: badgeColor,
            size: 3.w,
          ),
          SizedBox(width: 1.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _onCustomerTap(InvoiceModel customer) {
    // Navigate to customer detail screen or create new invoice with this customer
    Navigator.pushNamed(
      context,
      '/customer-detail',
      arguments: customer.customerId,
    );
  }

  Future<Map<String, dynamic>> _getInventoryMetrics() async {
    final inventoryService = InventoryService();
    final allItems = await inventoryService.getAllItems();
    final lowStockItems = await inventoryService.getLowStockItems();
    
    final inStockSKUs = allItems.where((item) => item.currentStock > 0).length;
    final totalUnits = allItems.fold<int>(0, (sum, item) => sum + item.currentStock.toInt());
    final inventoryValue = allItems.fold<double>(0, (sum, item) => sum + (item.currentStock * item.avgCost));
    
    return {
      'inStockSKUs': inStockSKUs,
      'lowStockCount': lowStockItems.length,
      'totalUnits': totalUnits,
      'inventoryValue': inventoryValue,
      'lowStockItems': lowStockItems,
    };
  }

  // Builds the inventory summary card with key metrics
  Widget _buildInventorySummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: AppTheme.createSophisticatedContainer(
        isLight: !isDark,
        borderRadius: 24.0,
        includeElevation: true,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/inventory-screen');
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      gradient: AppTheme.getSuccessGradient(!isDark),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryLight.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Summary',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Stock levels & inventory value',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (lowStockCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.orange,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$lowStockCount Low',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInventoryMetric(
                    value: inStockSKUs.toString(),
                    label: 'In Stock',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.primaryLight,
                    isDark: isDark,
                  ),
                  _buildInventoryMetric(
                    value: totalUnits.toString(),
                    label: 'Total Units',
                    icon: Icons.layers_outlined,
                    color: AppTheme.secondaryLight,
                    isDark: isDark,
                  ),
                  _buildInventoryMetric(
                    value: '₹${_formatCurrency(inventoryValue)}',
                    label: 'Total Value',
                    icon: Icons.attach_money_outlined,
                    color: AppTheme.accentGoldLight,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryMetric({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 5.w, color: color),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inventory',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/inventory-screen'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Compact Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  inStockSKUs.toString(),
                  'In Stock',
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildCompactMetric(
                  lowStockCount.toString(),
                  'Low Stock',
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  _formatNumber(totalUnits),
                  'Total Units',
                  Icons.widgets,
                  Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildCompactMetric(
                  '₹${_formatCurrency(inventoryValue)}',
                  'Value',
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Status Section
          if (lowStockItems.isNotEmpty) ...[
            _buildLowStockAlert(),
            SizedBox(height: 2.h),
            _buildReceiveStockButton(),
          ] else ...[
            _buildAllStockedWell(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 4.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber,
              color: Colors.orange.withOpacity(0.8),
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lowStockItems.length} items running low',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Restock needed soon',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 4.w,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveStockButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showReceiveStockDialog();
        },
        icon: Icon(Icons.arrow_downward_rounded, size: 5.w),
        label: Text(
          'Receive Stock',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue.withOpacity(0.8),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.blue.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildAllStockedWell() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.withOpacity(0.8), size: 6.w),
          SizedBox(width: 3.w),
          Text(
            'All stocked well',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_downward_rounded, color: Colors.blue.withOpacity(0.8), size: 6.w),
            ),
            SizedBox(width: 3.w),
            Text('Stock Actions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStockActionTile(
              'Receive Stock',
              'Add inventory from purchases',
              Icons.arrow_downward_rounded,
              Colors.blue,
              () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventory-screen');
              },
            ),
            SizedBox(height: 2.h),
            _buildStockActionTile(
              'Issue Stock',
              'Remove inventory for sales',
              Icons.arrow_upward_rounded,
              Colors.green,
              () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventory-screen');
              },
            ),
            SizedBox(height: 2.h),
            _buildStockActionTile(
              'Adjust Stock',
              'Manual stock corrections',
              Icons.build_rounded,
              Colors.orange,
              () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventory-screen');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.withOpacity(0.8), size: 5.w),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 4.w, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatLastUpdated(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
