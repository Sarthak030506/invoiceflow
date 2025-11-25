import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/catalog_item.dart';
import '../../services/inventory_service.dart';
import '../../services/catalog_service.dart';
import '../../services/stock_map_service.dart';
import '../../constants/app_scaling.dart';
import '../catalogue/business_type_selection_screen.dart';
import '../../widgets/rate_edit_dialog.dart';

class AddItemsDirectlyScreen extends StatefulWidget {
  @override
  State<AddItemsDirectlyScreen> createState() => _AddItemsDirectlyScreenState();
}

class _AddItemsDirectlyScreenState extends State<AddItemsDirectlyScreen> {
  final Map<int, _SelectedItem> _selectedItems = {};
  String _search = '';
  String _selectedCategory = 'All';
  final InventoryService _inventoryService = InventoryService();
  final CatalogService _catalogService = CatalogService.instance;
  final StockMapService _stockMapService = StockMapService();

  List<CatalogItem> _itemCatalog = [];
  Map<int, int> _stockMap = {};
  bool _catalogLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadStockMap();
  }

  Future<void> _loadCatalog() async {
    setState(() => _catalogLoading = true);
    try {
      final catalog = await _catalogService.getAllItems();
      if (mounted) {
        setState(() {
          _itemCatalog = catalog;
          _catalogLoading = false;
        });

        // If catalogue is empty, prompt user to set it up
        if (catalog.isEmpty) {
          _promptCatalogueSetup();
        }
      }
    } catch (e) {
      print('Error loading catalog: $e');
      // Fallback to static catalog
      if (mounted) {
        setState(() {
          _itemCatalog = ItemCatalog.items;
          _catalogLoading = false;
        });
      }
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

  int _getItemStock(int itemId) {
    return _stockMap[itemId] ?? 0;
  }

  Future<void> _editItem(CatalogItem item) async {
    final result = await RateEditDialog.show(
      context,
      item,
      onRateUpdated: () {
        _loadCatalog(); // Refresh catalog after update
        _loadStockMap(); // Refresh stock data
      },
    );
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
              Icon(Icons.inventory_2, color: Colors.green, size: 7.w),
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
                'Your product catalogue is empty. Set it up now to start adding items to inventory.',
                style: TextStyle(fontSize: 12.sp, height: 1.4),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Choose from 8 business types or create your own custom catalogue',
                        style: TextStyle(fontSize: 10.sp, color: Colors.green[900]),
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
                Navigator.of(context).pop(); // Also pop the add items screen
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
                      returnRoute: 'inventory',
                    ),
                  ),
                );

                // Reload catalogue if setup was completed
                if (result == true && mounted) {
                  _loadCatalog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

  Widget _buildFilterChip(String label, int count) {
    final bool isSelected = _selectedCategory == label;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: EdgeInsets.only(right: AppScaling.spacing),
        padding: EdgeInsets.symmetric(horizontal: AppScaling.spacing * 1.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
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
            SizedBox(width: AppScaling.spacingSmall),
            Container(
              padding: EdgeInsets.all(AppScaling.spacingSmall),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: AppScaling.small,
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
        title: Text('Add Items to Inventory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _catalogLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading catalogue...',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _buildItemsList(),
    );
  }

  Widget _buildItemsList() {
    List<CatalogItem> filteredItems = _itemCatalog;
    
    if (_search.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    
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

    return Column(
      children: [
        Padding(
          padding: AppScaling.defaultPadding,
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search items',
              hintText: 'Type to search...',
              prefixIcon: Icon(Icons.search, color: Colors.green),
              suffixIcon: _search.isNotEmpty ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => setState(() => _search = ''),
              ) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        
        Container(
          height: AppScaling.buttonHeight,
          margin: EdgeInsets.symmetric(horizontal: AppScaling.spacing * 1.5),
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
        
        Padding(
          padding: EdgeInsets.fromLTRB(AppScaling.spacing * 1.5, AppScaling.spacing, AppScaling.spacing * 1.5, AppScaling.spacingSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredItems.length} items available',
                style: TextStyle(color: Colors.grey[600], fontSize: AppScaling.small),
              ),
              if (_selectedItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppScaling.spacing * 1.5, vertical: AppScaling.spacingSmall),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedItems.length} selected',
                    style: TextStyle(
                      color: Colors.green,
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
              final isLowStock = currentStock <= 10;
              final isOutOfStock = currentStock <= 0;

              return Card(
                margin: AppScaling.cardMargin,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: selected ? Border.all(color: Colors.green, width: 2) : null,
                    ),
                    child: Padding(
                      padding: AppScaling.cardPadding2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: selected,
                                activeColor: Colors.green,
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
                              SizedBox(width: AppScaling.spacing),
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
                                              fontSize: AppScaling.h2,
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
                                    SizedBox(height: AppScaling.spacingSmall),
                                    Text(
                                      'Rate: ₹${item.rate.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: AppScaling.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          
                          if (selected)
                            Container(
                              margin: EdgeInsets.only(top: AppScaling.spacing),
                              padding: AppScaling.defaultPadding,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
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
                                            padding: EdgeInsets.all(AppScaling.spacing),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                bottomLeft: Radius.circular(8),
                                              ),
                                            ),
                                            child: Icon(Icons.remove, size: AppScaling.iconSize),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _showQuantityDialog(selectedItem!),
                                          child: Container(
                                            width: 60,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.symmetric(horizontal: AppScaling.spacing),
                                            child: Text(
                                              '${selectedItem?.quantity ?? 1}',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedItem!.quantity++;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: EdgeInsets.all(AppScaling.spacing),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                bottomRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: Icon(Icons.add, size: AppScaling.iconSize, color: Colors.white),
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
            padding: EdgeInsets.symmetric(horizontal: AppScaling.spacing * 2, vertical: AppScaling.spacing * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Items:',
                      style: TextStyle(fontSize: AppScaling.body, color: Colors.grey[600]),
                    ),
                    Text(
                      '${_selectedItems.length} items',
                      style: TextStyle(fontSize: AppScaling.body, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppScaling.spacing),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    onPressed: _selectedItems.isEmpty ? null : _addItemsToInventory,
                    icon: Icon(Icons.add_box, size: 22),
                    label: Text(
                      'Add to Inventory',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showQuantityDialog(_SelectedItem selectedItem) {
    final TextEditingController controller = TextEditingController(
      text: selectedItem.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Quantity',
            hintText: 'Enter quantity',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            errorText: null,
          ),
          onSubmitted: (value) {
            final quantity = int.tryParse(value);
            if (quantity != null && quantity > 0 && quantity <= 10000) {
              setState(() {
                selectedItem.quantity = quantity;
              });
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = controller.text.trim();
              final quantity = int.tryParse(value);

              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid positive number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (quantity > 10000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quantity cannot exceed 10,000'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                selectedItem.quantity = quantity;
              });
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItemsToInventory() async {
    try {
      // Show enhanced loading dialog with progress info
      showDialog(
        context: context,
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
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Adding to Inventory...',
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Processing ${_selectedItems.length} item${_selectedItems.length > 1 ? 's' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // OPTIMIZATION: Use batch method instead of sequential processing
      final itemsWithQuantities = _selectedItems.values.map((selectedItem) => {
        'item': selectedItem.item,
        'quantity': selectedItem.quantity.toDouble(),
      }).toList();

      await _inventoryService.batchAddItemsDirectlyToInventory(itemsWithQuantities);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedItems.length} items added to inventory successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(); // Go back to inventory screen
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding items: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SelectedItem {
  final CatalogItem item;
  int quantity;
  _SelectedItem({required this.item, this.quantity = 1});
}