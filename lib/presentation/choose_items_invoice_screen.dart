import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../models/catalog_item.dart';
import '../services/database_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../services/stock_map_service.dart';
import '../widgets/payment_details_widget.dart';
import './create_invoice/widgets/customer_input_widget.dart';
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
  StreamSubscription<void>? _inventorySubscription;
  
  // Static catalog and live stock
  static const List<CatalogItem> _itemCatalog = ItemCatalog.items;
  Map<int, int> _stockMap = {};
  
  // Performance optimizations
  Timer? _searchDebounce;
  
  // Configuration
  static const bool _allowNegativeStock = false;
  static const int _reorderPoint = 10;
  
  // Customer information
  String _customerName = '';
  String _customerPhone = '';
  String? _customerId;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _invoiceService = InvoiceService.instance;
    _customerService = CustomerService();
    _stockMapService = StockMapService();
    _loadStockMap();
    _inventorySubscription = _stockMapService.inventoryUpdates.listen((_) => _loadStockMap());
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
  
  Future<void> _loadStockMap() async {
    try {
      final stockMap = await _stockMapService.getCurrentStockMap();
      if (mounted) {
        setState(() {
          _stockMap = stockMap;
        });
      }
    } catch (e) {
      print('Error loading stock map: $e');
    }
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
  
  int _getItemStock(int itemId) {
    return _stockMap[itemId] ?? 0;
  }
  
  void _onCustomerSelected(String name, String phone, String? customerId) {
    setState(() {
      _customerName = name;
      _customerPhone = phone;
      _customerId = customerId;
    });
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
    List<CatalogItem> filteredItems = _itemCatalog;
    
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
            height: 5.h,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', filteredItems.length),
                _buildFilterChip('Kitchen', _itemCatalog.where((item) => item.name.toLowerCase().contains('kitchen')).length),
                _buildFilterChip('Cleaning', _itemCatalog.where((item) => 
                  item.name.toLowerCase().contains('clean') || 
                  item.name.toLowerCase().contains('phenyl') ||
                  item.name.toLowerCase().contains('mop')).length),
                _buildFilterChip('Containers', _itemCatalog.where((item) => item.name.toLowerCase().contains('container')).length),
                _buildFilterChip('Bags', _itemCatalog.where((item) => item.name.toLowerCase().contains('bag')).length),
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
                                              Container(
                                                width: 10.w,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(horizontal: 2.w),
                                                child: Text(
                                                  '${selectedItem?.quantity ?? 1}',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
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
                                      builder: (context) => Container(
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
                                                onCustomerSelected: _onCustomerSelected,
                                              ),
                                              SizedBox(height: 2.h),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.grey[300],
                                                        foregroundColor: Colors.black,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                  ),
                                                  SizedBox(width: 2.w),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.blue,
                                                        foregroundColor: Colors.white,
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
                                                            print('Error saving customer: $e');
                                                          }
                                                        }
                                                        
                                                        // Close customer info sheet and show payment details
                                                        Navigator.pop(context);
                                                        _showPaymentDetailsSheet(invoiceItems, totalAmount);
                                                      },
                                                      child: Text('Continue to Payment'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 2.h),
                                            ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Payment Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              PaymentDetailsWidget(
                totalAmount: totalAmount,
                invoiceType: widget.invoiceType,
                onPaymentDetailsSubmitted: (amountPaid, paymentMethod) async {
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
                    
                    // Create invoice with payment details and customer ID
                    final newInvoice = InvoiceModel(
                      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                      clientName: _customerName,
                      customerPhone: widget.invoiceType == 'sales' ? _customerPhone : null,
                      customerId: widget.invoiceType == 'sales' ? _customerId : null,
                      date: DateTime.now(),
                      revenue: totalAmount,
                      status: 'posted', // Always post invoices to process inventory
                      items: invoiceItems,
                      notes: null,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      invoiceType: widget.invoiceType,
                      amountPaid: amountPaid,
                      paymentMethod: paymentMethod,
                    );
                    
                    // Save the invoice to the database using InvoiceService
                    await _invoiceService.addInvoice(newInvoice);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice created and saved to database!')),
                    );
                    
                    // Close the payment details bottom sheet
                    Navigator.of(context).pop();
                    
                    // Navigate directly to home screen and clear all previous screens
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',  // Home route
                      (route) => false,  // Remove all previous routes
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
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

