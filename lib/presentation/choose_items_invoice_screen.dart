import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../models/catalog_item.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../services/stock_map_service.dart';
import '../services/return_service.dart';
import '../services/catalog_service.dart';
import '../services/inventory_service.dart';
import '../utils/app_logger.dart';
import '../widgets/enhanced_payment_details_widget.dart';
import '../widgets/rate_edit_dialog.dart';
import './create_invoice/widgets/customer_input_widget.dart';
import './catalogue/business_type_selection_screen.dart';
import 'dart:async';

class ChooseItemsInvoiceScreen extends StatefulWidget {
  final String invoiceType; // 'sales' or 'purchase'
  
  const ChooseItemsInvoiceScreen({
    Key? key,
    required this.invoiceType,
  }) : super(key: key);

  @override
  State<ChooseItemsInvoiceScreen> createState() => _ChooseItemsInvoiceScreenState();
}

class _ChooseItemsInvoiceScreenState extends State<ChooseItemsInvoiceScreen> with WidgetsBindingObserver {
  final Map<int, _SelectedItem> _selectedItems = {};
  String _search = '';
  String _selectedCategory = 'All';
  late final InvoiceService _invoiceService;
  late final CustomerService _customerService;
  late final StockMapService _stockMapService;
  late final ReturnService _returnService;
  late final CatalogService _catalogService;
  late final InventoryService _inventoryService;
  StreamSubscription<void>? _inventorySubscription;

  // Dynamic catalog with custom rates and live stock
  List<CatalogItem> _itemCatalog = [];
  Map<int, int> _stockMap = {};
  bool _catalogLoading = true;
  
  // Performance optimizations
  Timer? _searchDebounce;
  
  // Configuration
  static const bool _allowNegativeStock = false;
  static const int _reorderPoint = 10;
  
  // Customer information
  String _customerName = '';
  String _customerPhone = '';
  String? _customerId;
  double _pendingRefundAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _invoiceService = InvoiceService.instance;
    _customerService = CustomerService.instance;
    _stockMapService = StockMapService();
    _returnService = ReturnService.instance;
    _catalogService = CatalogService.instance;
    _inventoryService = InventoryService();
    _loadCatalog();
    _loadStockMap();
    _inventorySubscription = _stockMapService.inventoryUpdates.listen((_) {
      _loadStockMap();
      // For sales invoices, also reload catalog when inventory changes
      if (widget.invoiceType == 'sales') {
        _loadCatalog();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inventorySubscription?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStockMap();
    }
  }
  
  Future<void> _loadCatalog() async {
    try {
      List<CatalogItem> catalog;

      if (widget.invoiceType == 'sales') {
        // For SALES: Load only items from inventory (items with stock > 0)
        final sellableItems = await _inventoryService.getSellableItems();
        catalog = sellableItems.map((item) => CatalogItem(
          id: int.tryParse(item['id']?.toString() ?? '0') ?? 0,
          name: item['name'] ?? '',
          rate: (item['avgCost'] as num?)?.toDouble() ?? 0.0,
        )).toList();
      } else {
        // For PURCHASE: Load all items from catalogue
        catalog = await _catalogService.getAllItems();
      }

      if (mounted) {
        setState(() {
          _itemCatalog = catalog;
          _catalogLoading = false;
        });

        // If no items available, show appropriate prompt
        if (catalog.isEmpty) {
          if (widget.invoiceType == 'sales') {
            _promptNoInventory();
          } else {
            _promptCatalogueSetup();
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error loading catalog', 'ChooseItemsInvoice', e);
      // Fallback to static catalog only for purchase invoices
      if (mounted && widget.invoiceType == 'purchase') {
        setState(() {
          _itemCatalog = ItemCatalog.items;
          _catalogLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _itemCatalog = [];
          _catalogLoading = false;
        });
      }
    }
  }

  Future<void> _editItem(CatalogItem item) async {
    final result = await RateEditDialog.show(
      context,
      item,
      onRateUpdated: () {
        _loadCatalog(); // Refresh catalog after update
      },
    );
  }

  Future<void> _loadStockMap() async {
    try {
      final stockMap = await _stockMapService.getCurrentStockMap();
      if (mounted) {
        setState(() {
          _stockMap = stockMap;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading stock map', 'ChooseItemsInvoice', e);
    }
  }

  void _promptCatalogueSetup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.inventory_2, color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green, size: 7.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Set Up Your Catalogue',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your product catalogue is empty. Set it up now to start creating ${widget.invoiceType} invoices.',
                style: TextStyle(fontSize: 12.sp, height: 1.4),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Choose from 8 business types or create your own custom catalogue',
                        style: TextStyle(fontSize: 10.sp, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Also pop the invoice screen
              },
              child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Navigate to catalogue setup
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BusinessTypeSelectionScreen(
                      isFirstTimeSetup: false,
                      returnRoute: 'invoice',
                    ),
                  ),
                );

                // Reload catalogue if setup was completed
                if (result == true && mounted) {
                  _loadCatalog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Set Up Catalogue', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    });
  }

  void _promptNoInventory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 7.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'No Items in Inventory',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You don\'t have any items in your inventory to sell. Add inventory first before creating sales invoices.',
                style: TextStyle(fontSize: 12.sp, height: 1.4),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Create a purchase invoice to add items to your inventory',
                        style: TextStyle(fontSize: 10.sp, color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Also pop the invoice screen
              },
              child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close sales invoice screen
                // User should navigate to Inventory or create Purchase Invoice
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('OK', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _search = value;
        });
      }
    });
  }

  void _showQuantityInputDialog(BuildContext context, CatalogItem item, _SelectedItem selectedItem, int currentStock) {
    final TextEditingController quantityController = TextEditingController(text: selectedItem.quantity.toString());
    final Color itemColor = widget.invoiceType == 'sales' ? Colors.blue : Colors.green;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: itemColor),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Enter Quantity',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 2.h),
              if (widget.invoiceType == 'sales')
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, size: 4.w, color: Colors.grey.shade600),
                      SizedBox(width: 2.w),
                      Text(
                        'Available: ${currentStock.toInt()} units',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  prefixIcon: Icon(Icons.format_list_numbered, color: itemColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: itemColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onSubmitted: (value) {
                  _updateQuantityFromDialog(dialogContext, item, selectedItem, quantityController.text, currentStock);
                },
              ),
              SizedBox(height: 1.h),
              Text(
                'Price per unit: ₹${item.rate.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateQuantityFromDialog(dialogContext, item, selectedItem, quantityController.text, currentStock);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: itemColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _updateQuantityFromDialog(BuildContext dialogContext, CatalogItem item, _SelectedItem selectedItem, String inputText, int currentStock) {
    final int? newQuantity = int.tryParse(inputText.trim());

    // Validation
    if (newQuantity == null || newQuantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Stock validation for sales invoices
    if (widget.invoiceType == 'sales' && !_allowNegativeStock && newQuantity > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${currentStock.toInt()} units available in stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update quantity
    setState(() {
      selectedItem.quantity = newQuantity;
    });

    // Close dialog
    Navigator.of(dialogContext).pop();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quantity updated to $newQuantity'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  int _getItemStock(int itemId) {
    return _stockMap[itemId] ?? 0;
  }
  
  void _onCustomerSelected(String name, String phone, String? customerId) async {
    setState(() {
      _customerName = name;
      _customerPhone = phone;
      _customerId = customerId;
      _pendingRefundAmount = 0.0; // Reset initially
    });

    // For sales invoices, check if customer has pending refund
    if (widget.invoiceType == 'sales' && customerId != null) {
      try {
        final customer = await _customerService.getCustomerById(customerId);
        if (customer != null && customer.pendingReturnAmount > 0) {
          setState(() {
            _pendingRefundAmount = customer.pendingReturnAmount;
          });
        }
      } catch (e) {
        AppLogger.error('Error fetching customer refund', 'ChooseItemsInvoice', e);
      }
    }
  }

  /// Get count of available items (respecting inventory filter for sales)
  int _getAvailableItemsCount() {
    if (widget.invoiceType == 'sales') {
      // Only count items that exist in inventory
      return _itemCatalog.where((item) => _stockMap.containsKey(item.id)).length;
    }
    return _itemCatalog.length;
  }

  /// Get count of items in a category (respecting inventory filter for sales)
  int _getCategoryItemCount(String keyword) {
    var items = _itemCatalog;

    // For sales invoices, only count items in inventory
    if (widget.invoiceType == 'sales') {
      items = items.where((item) => _stockMap.containsKey(item.id)).toList();
    }

    // Apply category filter
    switch (keyword) {
      case 'clean':
        return items.where((item) {
          final name = item.name.toLowerCase();
          return name.contains('clean') ||
                 name.contains('phenyl') ||
                 name.contains('mop');
        }).length;
      default:
        return items.where((item) => item.name.toLowerCase().contains(keyword)).length;
    }
  }

  Widget _buildFilterChip(String label, int count) {
    final bool isSelected = _selectedCategory == label;
    final color = widget.invoiceType == 'sales' ? Colors.blue : Colors.green;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(width: 1.w),
            Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoiceType == 'sales' ? 'Sales Invoice Items' : 'Purchase Invoice Items'),
        backgroundColor: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Select items to add to your ${widget.invoiceType} invoice'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _buildItemsList(),
    );
  }


  Widget _buildItemsList() {
    // Show loading indicator while catalog is loading
    if (_catalogLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading items...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    List<CatalogItem> filteredItems = _itemCatalog;

    // For sales invoices, only show items that exist in inventory
    if (widget.invoiceType == 'sales') {
      filteredItems = filteredItems
          .where((item) => _stockMap.containsKey(item.id))
          .toList();
    }

    // Apply search filter
    if (_search.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredItems = filteredItems.where((item) {
        final name = item.name.toLowerCase();
        switch (_selectedCategory) {
          case 'Kitchen':
            return name.contains('kitchen');
          case 'Cleaning':
            return name.contains('clean') ||
                   name.contains('phenyl') ||
                   name.contains('mop');
          case 'Containers':
            return name.contains('container');
          case 'Bags':
            return name.contains('bag');
          default:
            return true;
        }
      }).toList();
    }
    final total = _selectedItems.values.fold<double>(0, (sum, si) => sum + si.amount);

    return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search items',
                hintText: 'Type to search...',
                prefixIcon: Icon(Icons.search, color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green),
                suffixIcon: _search.isNotEmpty ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => setState(() => _search = ''),
                ) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Category chips
          Container(
            constraints: BoxConstraints(
              minHeight: 4.h,
              maxHeight: 6.h,
            ),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', _getAvailableItemsCount()),
                _buildFilterChip('Kitchen', _getCategoryItemCount('kitchen')),
                _buildFilterChip('Cleaning', _getCategoryItemCount('clean')),
                _buildFilterChip('Containers', _getCategoryItemCount('container')),
                _buildFilterChip('Bags', _getCategoryItemCount('bag')),
              ],
            ),
          ),
          
          // Selected items count
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 2.w, 3.w, 1.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredItems.length} items available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                ),
                if (_selectedItems.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: widget.invoiceType == 'sales' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedItems.length} selected',
                      style: TextStyle(
                        color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, idx) {
                final item = filteredItems[idx];
                final itemId = item.id;
                final selected = _selectedItems.containsKey(itemId);
                final selectedItem = _selectedItems[itemId];
                final currentStock = _getItemStock(itemId);
                final isLowStock = currentStock <= _reorderPoint;
                final isOutOfStock = currentStock <= 0;
                final itemColor = widget.invoiceType == 'sales' ? Colors.blue : Colors.green;
                
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                  elevation: Theme.of(context).cardTheme.elevation,
                  shape: Theme.of(context).cardTheme.shape,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedItems.remove(itemId);
                        } else {
                          _selectedItems[itemId] = _SelectedItem(item: item, quantity: 1);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(color: itemColor, width: 2) : null,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(2.w),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Checkbox and item details
                                Checkbox(
                                  value: selected,
                                  activeColor: itemColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedItems[itemId] = _SelectedItem(item: item, quantity: 1);
                                      } else {
                                        _selectedItems.remove(itemId);
                                      }
                                    });
                                  },
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock ? Colors.red.withOpacity(0.1) : 
                                                     isLowStock ? Colors.orange.withOpacity(0.1) : 
                                                     Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isOutOfStock ? Colors.red : 
                                                       isLowStock ? Colors.orange : 
                                                       Colors.green,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Stock: $currentStock',
                                              style: TextStyle(
                                                color: isOutOfStock ? Colors.red : 
                                                       isLowStock ? Colors.orange : 
                                                       Colors.green,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        'Rate: ₹${item.rate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Only show edit button for sales invoices (inventory items)
                            if (widget.invoiceType == 'sales')
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () => _editItem(item),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 4.5.w,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 1.h),

                            // Quantity controls (only show if selected)
                            if (selected)
                              Container(
                                margin: EdgeInsets.only(top: 2.w),
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: itemColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Quantity:',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Spacer(),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (selectedItem!.quantity > 1) {
                                                      selectedItem.quantity--;
                                                    }
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: EdgeInsets.all(1.w),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(8),
                                                      bottomLeft: Radius.circular(8),
                                                    ),
                                                  ),
                                                  child: Icon(Icons.remove, size: 5.w),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  _showQuantityInputDialog(context, item, selectedItem!, currentStock);
                                                },
                                                child: Container(
                                                  width: 10.w,
                                                  alignment: Alignment.center,
                                                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                                                  child: Text(
                                                    '${selectedItem?.quantity ?? 1}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: itemColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  final newQty = selectedItem!.quantity + 1;
                                                  if (widget.invoiceType == 'sales' && !_allowNegativeStock && newQty > currentStock) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Only ${currentStock.toInt()} in stock.'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  } else {
                                                    setState(() {
                                                      selectedItem!.quantity = newQty;
                                                    });
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: EdgeInsets.all(1.w),
                                                  decoration: BoxDecoration(
                                                    color: itemColor,
                                                    borderRadius: BorderRadius.only(
                                                      topRight: Radius.circular(8),
                                                      bottomRight: Radius.circular(8),
                                                    ),
                                                  ),
                                                  child: Icon(Icons.add, size: 5.w, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          '₹${(selectedItem?.amount ?? 0).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: itemColor,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.invoiceType == 'sales' && _allowNegativeStock && selectedItem != null && selectedItem!.quantity > currentStock)
                                      Container(
                                        margin: EdgeInsets.only(top: 1.h),
                                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange, width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.warning_amber, size: 4.w, color: Colors.orange),
                                            SizedBox(width: 1.w),
                                            Text(
                                              'Stock will go negative',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedItems.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Items:',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                      Text(
                        '${_selectedItems.length} items',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18.sp, 
                          fontWeight: FontWeight.bold,
                          color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 5.h,
                      maxHeight: 7.h,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      ),
                      onPressed: _selectedItems.isEmpty ? null : () {
                        final items = _selectedItems.values.map((si) => {
                          'name': si.item.name,
                          'rate': si.item.rate,
                          'quantity': si.quantity,
                          'amount': si.amount,
                        }).toList();
                        final totalAmount = items.fold<double>(0, (sum, i) => sum + (i['amount'] as double));

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  widget.invoiceType == 'sales' ? Icons.shopping_cart : Icons.inventory,
                                  color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                                ),
                                SizedBox(width: 2.w),
                                Text('${widget.invoiceType.substring(0, 1).toUpperCase()}${widget.invoiceType.substring(1)} Invoice'),
                              ],
                            ),
                            content: Container(
                              width: double.maxFinite,
                              constraints: BoxConstraints(maxHeight: 50.h),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Summary',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                                  ),
                                  Divider(),
                                  Expanded(
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        ...items.map((i) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 1.h),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '${i['name']}',
                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'x${i['quantity']}',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${i['rate']}',
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${(i['amount'] as double? ?? 0).toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '₹${totalAmount.toStringAsFixed(2)}', 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16.sp,
                                          color: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                                onPressed: () async {
                                  final invoiceItems = items.map((i) => InvoiceItem(
                                    name: i['name'] as String,
                                    quantity: i['quantity'] as int,
                                    price: i['rate'] as double,
                                  )).toList();
                                  // Close the invoice summary dialog
                                  Navigator.of(context).pop();
                                  
                                  // For sales invoices, show customer information input first
                                  if (widget.invoiceType == 'sales') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => StatefulBuilder(
                                        builder: (context, setModalState) => Container(
                                          padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context).viewInsets.bottom,
                                            left: 4.w,
                                            right: 4.w,
                                            top: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 10.w,
                                                  height: 0.5.h,
                                                  margin: EdgeInsets.only(bottom: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                Text(
                                                  'Customer Information',
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                CustomerInputWidget(
                                                  initialName: _customerName,
                                                  initialPhone: _customerPhone,
                                                  onCustomerSelected: (name, phone, customerId) {
                                                    _onCustomerSelected(name, phone, customerId);
                                                    // Rebuild modal to enable/disable button
                                                    setModalState(() {});
                                                  },
                                                ),
                                                SizedBox(height: 2.h),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                                                          side: BorderSide(color: Colors.grey.shade400),
                                                          foregroundColor: Colors.black87,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                        },
                                                        child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                                                      ),
                                                    ),
                                                    SizedBox(width: 3.w),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                                                          backgroundColor: Colors.blue,
                                                          foregroundColor: Colors.white,
                                                          disabledBackgroundColor: Colors.grey.shade300,
                                                          disabledForegroundColor: Colors.grey.shade600,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        onPressed: _customerPhone.isEmpty ? null : () async {
                                                        // Save customer if needed
                                                        if (_customerId == null && _customerPhone.isNotEmpty) {
                                                          try {
                                                            final customer = await _customerService.addCustomer(
                                                              _customerName.isEmpty ? 'Customer' : _customerName,
                                                              _customerPhone,
                                                            );
                                                            _customerId = customer.id;
                                                          } catch (e) {
                                                            AppLogger.error('Error saving customer', 'ChooseItemsInvoice', e);
                                                          }
                                                        }
                                                        
                                                        // Close customer info sheet and show payment details
                                                        if (!mounted) return;
                                                        if (Navigator.of(context).canPop()) {
                                                          Navigator.pop(context);
                                                        }
                                                        _showPaymentDetailsSheet(invoiceItems, totalAmount);
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.arrow_forward, size: 16),
                                                          SizedBox(width: 1.w),
                                                          Flexible(
                                                            child: Text(
                                                              'Continue to Payment',
                                                              style: TextStyle(fontSize: 13.sp),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 2.h),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    );
                                  } else {
                                    // For purchase invoices, go directly to payment details
                                    _showPaymentDetailsSheet(invoiceItems, totalAmount);
                                  }
                                },
                                child: Text('Continue'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Generate Invoice',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
  }
  
  void _showPaymentDetailsSheet(List<InvoiceItem> invoiceItems, double totalAmount) {
    // Capture a stable parent context from this State to avoid using a deactivated sheet context
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(parentContext).viewInsets.bottom,
          left: 4.w,
          right: 4.w,
          top: 2.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              EnhancedPaymentDetailsWidget(
                totalAmount: totalAmount,
                invoiceType: widget.invoiceType,
                pendingRefundAmount: _pendingRefundAmount,
                onPaymentDetailsSubmitted: (amountPaid, paymentMethod, invoiceNumber, invoiceDate) async {
                  // Show a blocking loader with progress message
                  showDialog(
                    context: parentContext,
                    barrierDismissible: false,
                    builder: (_) => WillPopScope(
                      onWillPop: () async => false,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          margin: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon background
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: widget.invoiceType == 'sales' ? Colors.blue.shade50 : Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.invoiceType == 'sales' ? Colors.blue.shade600 : Colors.green.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                'Processing Invoice...',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 1.5.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: widget.invoiceType == 'sales' ? Colors.blue.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Saving ${invoiceItems.length} item${invoiceItems.length > 1 ? 's' : ''}\nand updating inventory',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: widget.invoiceType == 'sales' ? Colors.blue.shade700 : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  try {
                    // For sales invoices, ensure customer exists and is linked
                    if (widget.invoiceType == 'sales' && _customerPhone.isNotEmpty && _customerId == null) {
                      // If we don't have a customerId yet, create or find the customer
                      final customer = await _customerService.addCustomer(
                        _customerName.isEmpty ? 'Customer' : _customerName,
                        _customerPhone,
                      );
                      _customerId = customer.id;
                    }

                    // Apply pending returns for sales invoices
                    String? returnNotes;
                    if (widget.invoiceType == 'sales' && _customerId != null && _pendingRefundAmount > 0) {
                      // The refund adjustment is already tracked separately in refundAdjustment field
                      // amountPaid should be exactly what the customer paid (the adjusted amount)
                      returnNotes = 'Return credit of ₹${_pendingRefundAmount.toStringAsFixed(2)} applied';

                      // Mark pending returns as applied/settled
                      await _returnService.applyPendingReturnsToInvoice(_customerId!, _pendingRefundAmount);
                    }

                    // Create invoice with payment details and customer ID
                    final now = DateTime.now();
                    final invoiceId = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9-_]'), '_');

                    AppLogger.debug('Creating invoice with refund adjustment: $_pendingRefundAmount', 'ChooseItemsInvoice');

                    // Calculate adjusted total for status determination
                    final adjustedTotal = totalAmount - _pendingRefundAmount;

                    // Determine invoice status based on payment
                    String invoiceStatus;
                    if ((amountPaid - adjustedTotal).abs() < 0.01) {
                      // Fully paid
                      invoiceStatus = 'paid';
                    } else if (amountPaid > 0.01) {
                      // Partially paid
                      invoiceStatus = 'partial';
                    } else {
                      // Not paid (due)
                      invoiceStatus = 'posted';
                    }

                    final newInvoice = InvoiceModel(
                      id: invoiceId,
                      invoiceNumber: invoiceNumber,
                      clientName: _customerName,
                      customerPhone: widget.invoiceType == 'sales' ? _customerPhone : null,
                      customerId: widget.invoiceType == 'sales' ? _customerId : null,
                      date: invoiceDate,
                      refundAdjustment: _pendingRefundAmount,
                      revenue: totalAmount,
                      status: invoiceStatus,
                      items: invoiceItems,
                      notes: returnNotes,
                      createdAt: now,
                      updatedAt: now,
                      invoiceType: widget.invoiceType,
                      amountPaid: amountPaid,
                      paymentMethod: paymentMethod,
                    );
                    
                    // Save the invoice to the database using InvoiceService
                    await _invoiceService.addInvoice(newInvoice);

                    if (!mounted) return;
                    // Dismiss loader
                    if (Navigator.of(parentContext, rootNavigator: true).canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Invoice created and saved to database!')),
                    );

                    // Close the payment details bottom sheet
                    if (Navigator.of(parentContext).canPop()) {
                      Navigator.of(parentContext).pop();
                    }

                    // Navigate directly to home screen and clear all previous screens
                    Navigator.of(parentContext).pushNamedAndRemoveUntil(
                      '/',  // Home route
                      (route) => false,  // Remove all previous routes
                    );
                  } catch (e) {
                    if (!mounted) return;
                    // Ensure loader is dismissed on error
                    if (Navigator.of(parentContext, rootNavigator: true).canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Error saving invoice: ${e.toString()}')),
                    );
                  }
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
  
}

class _SelectedItem {
  final CatalogItem item;
  int quantity;
  _SelectedItem({required this.item, this.quantity = 1});
  double get amount => quantity * item.rate;
}

