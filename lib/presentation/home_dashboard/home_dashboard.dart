import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../invoice_type_selection_screen.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../services/csv_invoice_service.dart';
import '../../services/notification_service.dart';
import '../../services/inventory_service.dart';
import '../../services/event_service.dart';
import './widgets/metric_card_widget.dart';
import './widgets/recent_invoice_item_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';
import '../../animations/fluid_animations.dart';
import 'dart:async';

class HomeDashboard extends StatefulWidget {
  final String csvPath;
  const HomeDashboard({required this.csvPath, super.key});

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

      // Validate CSV connection in background without blocking UI
      Future.microtask(() => _validateConnection());
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
      print('Connection validation error: $e');
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
    if (index == _selectedIndex) return; // Don't navigate if already on current tab
    
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, '/invoices-list-screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/analytics-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/customers-screen');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile-screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 12.h,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Good ${_getGreeting()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              'John Doe',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(2.w),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: CustomIconWidget(
                                  iconName: 'notifications_outlined',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  size: 5.w,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.w),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2.w),
                                child: CustomImageWidget(
                                  imageUrl:
                                      "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
                                  width: 10.w,
                                  height: 10.w,
                                  fit: BoxFit.cover,
                                ),
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
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: _buildPendingFollowupsSection(),
                            ),

                            SizedBox(height: 4.h),

                            // Send To Section
                            Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 2.h),
                              padding: EdgeInsets.all(5.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF8FFFE),
                                    Color(0xFFF0F9FF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Recipients',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'Send to',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                      letterSpacing: -0.5,
                                    ),
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

                            SizedBox(height: 4.h),

                            // Inventory Summary Card
                            _buildInventorySummaryCard(),

                            SizedBox(height: 4.h),

                            // Recent Invoices Section
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Invoices',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/invoices-list-screen'),
                                    child: Text(
                                      'View All',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 1.h),

                            recentInvoices.isEmpty
                                ? _buildEmptyState()
                                : Container(
                                    height: 25.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                                      itemCount: recentInvoices.length,
                                      key: PageStorageKey('recent_invoices'),
                                      itemBuilder: (context, index) {
                                        final invoice = recentInvoices[index];
                                        return FluidAnimations.createStaggeredListAnimation(
                                          index: index,
                                          child: Container(
                                            width: 75.w,
                                            margin: EdgeInsets.only(right: 3.w),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: invoice.invoiceType == 'sales'
                                                    ? [Colors.blue.shade50, Colors.blue.shade100]
                                                    : [Colors.green.shade50, Colors.green.shade100],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: invoice.invoiceType == 'sales' ? Colors.blue.shade200 : Colors.green.shade200,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (invoice.invoiceType == 'sales' ? Colors.blue : Colors.green).withOpacity(0.1),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 5),
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => Navigator.pushNamed(
                                                  context,
                                                  '/invoice-detail-screen',
                                                  arguments: invoice,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(4.w),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                                                            decoration: BoxDecoration(
                                                              color: invoice.invoiceType == 'sales' ? Colors.blue.shade600 : Colors.green.shade600,
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              invoice.invoiceType.toUpperCase(),
                                                              style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                                                            decoration: BoxDecoration(
                                                              color: invoice.status.toLowerCase() == 'paid' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              invoice.status.toUpperCase(),
                                                              style: TextStyle(
                                                                color: invoice.status.toLowerCase() == 'paid' ? Colors.green.shade700 : Colors.orange.shade700,
                                                                fontSize: 9.sp,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 2.h),
                                                      Text(
                                                        invoice.invoiceNumber,
                                                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                                      ),
                                                      SizedBox(height: 0.5.h),
                                                      Text(
                                                        invoice.clientName,
                                                        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 1.h),
                                                      Text(
                                                        invoice.getFormattedDate(),
                                                        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                                                      ),
                                                      Spacer(),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            '₹${invoice.total.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 18.sp,
                                                              fontWeight: FontWeight.bold,
                                                              color: invoice.invoiceType == 'sales' ? Colors.blue.shade700 : Colors.green.shade700,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.arrow_forward_ios,
                                                            size: 4.w,
                                                            color: Colors.grey.shade400,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                            SizedBox(height: 2.h),

                            // Data Source Info
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Source: Local Database',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
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
                                          color: isDark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
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
              child: FloatingActionButton(
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
                              leading: Icon(Icons.document_scanner_rounded, color: Theme.of(context).colorScheme.primary),
                              title: Text('Smart Scan Invoice'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
                              title: Text('Test Notification'),
                              onTap: () async {
                                Navigator.pop(context);
                                await NotificationService().testNotification(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.money_off_outlined, color: Colors.orange),
                              title: Text('Mark 3 Invoices Unpaid'),
                              onTap: () async {
                                Navigator.pop(context);
                                await _invoiceService.markLastThreeInvoicesUnpaid();
                                await _loadDashboardData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Last 3 sales invoices marked as unpaid'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.add_circle_outline, color: Colors.green),
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
                child: Icon(
                  Icons.add_rounded,
                  size: 7.w,
                  color: Colors.white,
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 8,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildPendingFollowupsSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter truly pending invoices from all invoices (not just recent)
    final pendingInvoices = allInvoices
        .where((invoice) => 
            invoice.invoiceType == 'sales' && 
            invoice.status.toLowerCase() != 'paid' &&
            invoice.paymentStatus == PaymentStatus.balanceDue &&
            (invoice.followUpDate == null || 
             DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isBefore(today) ||
             DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isAtSameMomentAs(today)))
        .toList();
    
    // Sort by remaining amount (highest first) and date (oldest first)
    pendingInvoices.sort((a, b) {
      final amountComparison = b.absoluteRemainingAmount.compareTo(a.absoluteRemainingAmount);
      if (amountComparison != 0) return amountComparison;
      return a.date.compareTo(b.date);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Follow-ups',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        
        if (pendingInvoices.isEmpty)
          _buildAllCaughtUpCard()
        else
          _buildPendingPaymentsCard(pendingInvoices),
      ],
    );
  }
  
  Widget _buildAllCaughtUpCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius,
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).cardTheme.shadowColor ?? Colors.green.withOpacity(0.3),
            blurRadius: Theme.of(context).cardTheme.elevation ?? 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 8.w,
              ),
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
                    'No pending payments to review',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
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
  
  Widget _buildPendingPaymentsCard(List<InvoiceModel> pendingInvoices) {
    final totalPending = pendingInvoices.fold<double>(
      0.0, (sum, invoice) => sum + invoice.remainingAmount);
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 7.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pendingInvoices.length}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 32.sp,
                        ),
                      ),
                      Text(
                        'Invoice${pendingInvoices.length > 1 ? 's' : ''} Need Action',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Total: ₹${_formatCurrency(totalPending)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
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
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                ...pendingInvoices.take(4).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final invoice = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildEnhancedPendingItem(invoice),
                        ),
                      );
                    },
                  );
                }),
                
                if (pendingInvoices.length > 4)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 3.h),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/invoices-list-screen'),
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: Colors.amber.shade700,
                        size: 5.w,
                      ),
                      label: Text(
                        'View All ${pendingInvoices.length} Invoices',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.amber.shade300, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
  
  Widget _buildEnhancedPendingItem(InvoiceModel invoice) {
    final isOverdue = invoice.followUpDate != null && 
        invoice.followUpDate!.isBefore(DateTime.now().subtract(Duration(days: 1)));
    
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(4.w),
        leading: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOverdue 
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOverdue ? Icons.schedule_outlined : Icons.access_time_rounded,
            color: Colors.white,
            size: 6.w,
          ),
        ),
        title: Text(
          invoice.clientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isOverdue 
              ? 'Invoice #${invoice.invoiceNumber} • Overdue'
              : 'Invoice #${invoice.invoiceNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${_formatCurrency(invoice.remainingAmount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isOverdue ? Colors.red.shade700 : Colors.amber.shade700,
              ),
            ),
            IconButton(
              onPressed: () => _showSnoozeDialog(invoice),
              icon: Icon(
                Icons.schedule_outlined,
                color: Colors.amber.shade600,
                size: 5.w,
              ),
              padding: EdgeInsets.all(1.w),
              constraints: BoxConstraints(minWidth: 8.w, minHeight: 8.w),
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          '/invoice-detail-screen',
          arguments: invoice,
        ),
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

  List<Widget> _buildRecentCustomers() {
    final uniqueCustomers = <String, InvoiceModel>{};
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    
    // Get unique customers from recent invoices, prioritizing most recent
    for (final invoice in allInvoices.reversed) {
      if (!uniqueCustomers.containsKey(invoice.clientName) && uniqueCustomers.length < 6) {
        uniqueCustomers[invoice.clientName] = invoice;
      }
    }
    
    return uniqueCustomers.entries.map((entry) {
      final index = uniqueCustomers.keys.toList().indexOf(entry.key);
      final customer = entry.value;
      final initials = customer.clientName.split(' ').map((name) => name.isNotEmpty ? name[0] : '').take(2).join();
      
      return Container(
        margin: EdgeInsets.only(right: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/invoice-type-selection-screen');
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors[index % colors.length].shade400, colors[index % colors.length].shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              customer.clientName.length > 10 ? '${customer.clientName.substring(0, 10)}...' : customer.clientName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
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
    return GestureDetector(
      onTap: () {
        // Prevent any parent gestures from being triggered
        FocusScope.of(context).unfocus();
        // Navigate to inventory screen
        Navigator.pushNamed(context, '/inventory-screen');
      },
      behavior: HitTestBehavior.opaque, // Ensure taps are captured by this widget
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventory Summary',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lowStockCount > 0 ? '$lowStockCount Low Stock' : 'All Good' }',
                    style: TextStyle(
                      color: lowStockCount > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInventoryMetric(
                  value: inStockSKUs.toString(),
                  label: 'In Stock SKUs',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue.shade700,
                ),
                _buildInventoryMetric(
                  value: totalUnits.toString(),
                  label: 'Total Units',
                  icon: Icons.layers_outlined,
                  color: Colors.blue.shade600,
                ),
                _buildInventoryMetric(
                  value: '\$${inventoryValue.toStringAsFixed(2)}',
                  label: 'Total Value',
                  icon: Icons.attach_money_outlined,
                  color: Colors.blue.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryMetric({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.blueGrey.shade600,
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
