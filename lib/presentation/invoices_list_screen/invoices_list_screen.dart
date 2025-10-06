import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/invoice_card_widget.dart';
import './widgets/search_bar_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';

class InvoicesListScreen extends StatefulWidget {
  final String csvPath;
  const InvoicesListScreen({required this.csvPath, Key? key}) : super(key: key);

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isMultiSelectMode = false;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  RangeValues _revenueRange = const RangeValues(0, 10000); // Match slider max value
  String? _selectedInvoiceType;
  List<String> _selectedInvoices = [];

  final InvoiceService _invoiceService = InvoiceService.instance;
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInvoices();
    _scrollController.addListener(_onScroll);
  }
  
  void _onTabChanged() {
    _filterInvoices();
  }
  


  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final invoices = await _invoiceService.fetchAllInvoices();
      setState(() {
        _allInvoices = invoices;
        _isLoading = false;
      });
      _filterInvoices();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Optionally handle error (e.g., show toast)
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreInvoices();
    }
  }

  void _loadMoreInvoices() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // Simulate loading more data
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _refreshInvoices() async {
    setState(() {
      
    });
    await _loadInvoices();
    setState(() {
      
    });
  }

  void _filterInvoices() {
    // Get base invoices for current tab
    List<InvoiceModel> baseInvoices;
    switch (_tabController.index) {
      case 0: // All
        baseInvoices = List.from(_allInvoices);
        break;
      case 1: // Sales
        baseInvoices = _allInvoices.where((invoice) => invoice.invoiceType == 'sales').toList();
        break;
      case 2: // Purchase
        baseInvoices = _allInvoices.where((invoice) => invoice.invoiceType == 'purchase').toList();
        break;
      default:
        baseInvoices = List.from(_allInvoices);
    }
    
    // Apply filters to base invoices
    final searchLower = _searchQuery.toLowerCase();
    
    List<InvoiceModel> filtered = baseInvoices.where((invoice) {
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = invoice.invoiceNumber.toLowerCase().contains(searchLower) ||
                            invoice.clientName.toLowerCase().contains(searchLower);
        if (!matchesSearch) return false;
      }

      if (_selectedDateRange != null) {
        final matchesDateRange = invoice.date.isAfter(_selectedDateRange!.start) && 
                               invoice.date.isBefore(_selectedDateRange!.end);
        if (!matchesDateRange) return false;
      }

      if (_selectedInvoiceType != null) {
        final matchesType = invoice.invoiceType == _selectedInvoiceType;
        if (!matchesType) return false;
      }

      final matchesRevenue = invoice.total >= _revenueRange.start && 
                           invoice.total <= _revenueRange.end;
      if (!matchesRevenue) return false;

      return true;
    }).toList();

    setState(() {
      _filteredInvoices = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterInvoices();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        selectedDateRange: _selectedDateRange,
        revenueRange: _revenueRange,
        selectedInvoiceType: _selectedInvoiceType,
        onDateRangeChanged: (range) {
          setState(() {
            _selectedDateRange = range;
          });
        },
        onRevenueRangeChanged: (range) {
          setState(() {
            _revenueRange = range;
          });
        },
        onInvoiceTypeChanged: (type) {
          setState(() {
            _selectedInvoiceType = type;
          });
        },
        onApplyFilters: () {
          _filterInvoices();
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() {
            _selectedDateRange = null;
            _revenueRange = const RangeValues(0, 10000);
            _selectedInvoiceType = null;
          });
          _filterInvoices();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedInvoices.clear();
      }
    });
  }

  void _toggleInvoiceSelection(String invoiceId) {
    setState(() {
      if (_selectedInvoices.contains(invoiceId)) {
        _selectedInvoices.remove(invoiceId);
      } else {
        _selectedInvoices.add(invoiceId);
      }
    });
  }

  void _deleteSelectedInvoices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Invoices',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete ₹${_selectedInvoices.length} selected invoice(s)?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final selectedCount = _selectedInvoices.length;
              final selectedIds = List<String>.from(_selectedInvoices);
              
              Navigator.pop(context); // Close dialog first
              
              try {
                // Delete invoices from database
                for (final invoiceId in selectedIds) {
                  await _invoiceService.deleteInvoice(invoiceId);
                  print('Deleted invoice from database: $invoiceId'); // Debug log
                }
                
                // Refresh the invoice list from database
                await _loadInvoices();
                
                setState(() {
                  _selectedInvoices.clear();
                  _isMultiSelectMode = false;
                });
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$selectedCount invoice(s) deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Show error message if deletion fails
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting invoices: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                print('Error deleting invoices: $e'); // Debug log
              }
            },  
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onInvoiceTap(InvoiceModel invoice) {
    if (_isMultiSelectMode) {
      _toggleInvoiceSelection(invoice.id);
    } else {
      Navigator.pushNamed(
        context,
        '/invoice-detail-screen',
        arguments: invoice,
      );
    }
  }

  void _onInvoiceLongPress(InvoiceModel invoice) {
    if (!_isMultiSelectMode) {
      _toggleMultiSelect();
      _toggleInvoiceSelection(invoice.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Calculate counts for each tab
    final allCount = _allInvoices.length;
    final salesCount = _allInvoices.where((invoice) => invoice.invoiceType == 'sales').length;
    final purchaseCount = _allInvoices.where((invoice) => invoice.invoiceType == 'purchase').length;
    
    return AppBar(
      backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
      elevation: AppTheme.lightTheme.appBarTheme.elevation,
      bottom: !_isMultiSelectMode ? TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: 'All ($allCount)'),
          Tab(text: 'Sales ($salesCount)'),
          Tab(text: 'Purchase ($purchaseCount)'),
        ],
      ) : null,
      title: _isMultiSelectMode
          ? Text(
              '₹${_selectedInvoices.length} selected',
              style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
            )
          : Row(
              children: [
                Text(
                  'Invoices',
                  style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
                ),
                if (_selectedInvoiceType != null) ...[  
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _selectedInvoiceType == 'sales' 
                        ? Colors.blue.withOpacity(0.2) 
                        : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedInvoiceType == 'sales' ? 'SALES' : 'PURCHASE',
                      style: TextStyle(
                        color: _selectedInvoiceType == 'sales' ? Colors.blue : Colors.green,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      leading: _isMultiSelectMode
          ? IconButton(
              onPressed: _toggleMultiSelect,
              icon: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.appBarTheme.iconTheme?.color ??
                    AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            )
          : null,
      actions: _isMultiSelectMode
          ? [
              if (_selectedInvoices.isNotEmpty)
                IconButton(
                  onPressed: _deleteSelectedInvoices,
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 24,
                  ),
                ),
            ]
          : [
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: CustomIconWidget(
                  iconName: 'filter_list',
                  color: AppTheme.lightTheme.appBarTheme.iconTheme?.color ??
                      AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (!_isMultiSelectMode)
          SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
        Expanded(
          child: _filteredInvoices.isEmpty
              ? const EmptyStateWidget()
              : RefreshIndicator(
                  onRefresh: _refreshInvoices,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    // Use cacheExtent to improve scrolling performance
                    cacheExtent: 500,
                    itemCount: _filteredInvoices.length + (_isLoading ? 1 : 0),
                    // Add key to help Flutter optimize rebuilds
                    key: PageStorageKey('invoice_list'),
                    itemBuilder: (context, index) {
                      if (index == _filteredInvoices.length) {
                        return _buildLoadingIndicator();
                      }

                      final invoice = _filteredInvoices[index];
                      final isSelected =
                          _selectedInvoices.contains(invoice.id);

                      // Add key to each item for better list performance
                      return KeyedSubtree(
                        key: ValueKey(invoice.id),
                        child: InvoiceCardWidget(
                          invoice: invoice,
                          isMultiSelectMode: _isMultiSelectMode,
                          isSelected: isSelected,
                          onTap: () => _onInvoiceTap(invoice),
                          onLongPress: () => _onInvoiceLongPress(invoice),
                          onEdit: () {
                            // Handle edit action
                          },
                          onShare: () {
                            // Handle share action
                          },
                          onDelete: () {
                            // Handle delete action
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: const AppLoadingIndicator.inline(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return EnhancedBottomNav(
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/');
            break;
          case 1:
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/analytics-screen');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/customers-screen');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
    );
  }
}
