import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../../services/items_service.dart';
import '../../../providers/auth_provider.dart';
import '../../home_dashboard/home_dashboard.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  
  bool _isLoading = false;
  bool _isBulkMode = false;
  final List<Map<String, String>> _bulkItems = [];
  final List<ProductCatalogItem> _addedItems = []; // Track added items
  final ItemsService _itemsService = ItemsService();

  @override
  void initState() {
    super.initState();
    // Set default values
    _categoryController.text = 'General';
    _unitController.text = 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Entry'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isBulkMode = !_isBulkMode;
              });
            },
            icon: Icon(_isBulkMode ? Icons.person : Icons.group),
            tooltip: _isBulkMode ? 'Single Mode' : 'Bulk Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeToggle(),
            SizedBox(height: 3.h),
            if (_isBulkMode) 
              _buildBulkEntryMode()
            else 
              _buildSingleEntryMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.orange, size: 6.w),
              SizedBox(width: 3.w),
              Text(
                _isBulkMode ? 'Bulk Entry Mode' : 'Single Entry Mode',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            _isBulkMode 
              ? 'Add multiple items quickly with just name and price'
              : 'Add one item at a time with complete details',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBulkMode ? null : () {
                    setState(() {
                      _isBulkMode = false;
                    });
                  },
                  icon: Icon(Icons.person, size: 4.w),
                  label: Text('Single Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBulkMode ? Colors.grey[300] : Colors.orange,
                    foregroundColor: _isBulkMode ? Colors.grey[600] : Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBulkMode ? null : () {
                    setState(() {
                      _isBulkMode = true;
                    });
                  },
                  icon: Icon(Icons.group, size: 4.w),
                  label: Text('Bulk Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBulkMode ? Colors.orange : Colors.grey[300],
                    foregroundColor: _isBulkMode ? Colors.white : Colors.grey[600],
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleEntryMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Details',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Item Name *',
              hintText: 'e.g., Paper Bag, Coffee Cup',
              prefixIcon: Icon(Icons.inventory, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Item name is required';
              }
              return null;
            },
          ),
          
          SizedBox(height: 3.h),
          
          // Price field
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price/Rate *',
              hintText: 'e.g., 50.00',
              prefixIcon: Icon(Icons.currency_rupee, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Price is required';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Enter a valid price';
              }
              return null;
            },
          ),
          
          SizedBox(height: 3.h),
          
          // Optional fields
          Text(
            'Optional Details',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    labelText: 'SKU',
                    hintText: 'e.g., ITM001',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          TextFormField(
            controller: _unitController,
            decoration: InputDecoration(
              labelText: 'Unit',
              hintText: 'pcs, kg, ltr',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          SizedBox(height: 4.h),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addSingleItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 4.w,
                        width: 4.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text('Adding item...'),
                    ],
                  )
                : Text(
                    'Add Item to List',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
          
          // Show added items and completion section
          if (_addedItems.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildAddedItemsSection(),
            SizedBox(height: 3.h),
            _buildCompletionSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkEntryMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Quick tip: Add items with just name and price. You can edit details later from inventory management.',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[700],
            ),
          ),
        ),
        
        SizedBox(height: 3.h),
        
        Text(
          'Quick Add Items',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        
        SizedBox(height: 2.h),
        
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Item Name',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              // Show existing bulk items
              if (_bulkItems.isNotEmpty) ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _bulkItems.length,
                  itemBuilder: (context, index) {
                    final item = _bulkItems[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['name']!,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '₹${item['price']}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[600],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _bulkItems.removeAt(index);
                              });
                            },
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            iconSize: 5.w,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),
              ],
              
              // Add new item form
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Item name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: EdgeInsets.all(3.w),
                      ),
                      onFieldSubmitted: (_) => _addToBulkList(),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        hintText: 'Price',
                        prefixText: '₹',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: EdgeInsets.all(3.w),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onFieldSubmitted: (_) => _addToBulkList(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addToBulkList,
                    icon: Icon(Icons.add_circle, color: Colors.orange, size: 8.w),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (_bulkItems.isNotEmpty) ...[
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addBulkItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 4.w,
                        width: 4.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text('Adding items...'),
                    ],
                  )
                : Text(
                    'Add ${_bulkItems.length} Items to List',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ],
      ],
    );
  }

  void _addToBulkList() {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    
    if (name.isNotEmpty && price.isNotEmpty && double.tryParse(price) != null) {
      setState(() {
        _bulkItems.add({
          'name': name,
          'price': price,
        });
        _nameController.clear();
        _priceController.clear();
      });
    }
  }

  Widget _buildAddedItemsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Added Items (${_addedItems.length})',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _addedItems.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final item = _addedItems[index];
              return Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${item.category} • ₹${item.rate.toStringAsFixed(0)} per ${item.unit}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                      iconSize: 5.w,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _completeOnboarding,
        icon: Icon(Icons.home_rounded),
        label: Text(
          'Done - Go to Home',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      // Mark onboarding as complete
      context.read<AuthProvider>().completeOnboarding();
      
      // Navigate to home dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing setup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSingleItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final item = ProductCatalogItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isEmpty 
            ? 'ITM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}' 
            : _skuController.text.trim(),
        category: _categoryController.text.trim(),
        unit: _unitController.text.trim(),
        rate: double.parse(_priceController.text),
        barcode: null,
        description: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _itemsService.addItem(item);
      
      // Add to local list to show in UI
      setState(() {
        _addedItems.add(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item added to your catalog!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _priceController.clear();
      _skuController.clear();
      _categoryController.text = 'General';
      _unitController.text = 'pcs';

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBulkItems() async {
    if (_bulkItems.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<ProductCatalogItem> catalogItems = [];
      
      for (int i = 0; i < _bulkItems.length; i++) {
        final itemData = _bulkItems[i];
        final item = ProductCatalogItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          name: itemData['name']!,
          sku: 'ITM${(DateTime.now().millisecondsSinceEpoch + i).toString().substring(8)}',
          category: 'General',
          unit: 'pcs',
          rate: double.parse(itemData['price']!),
          barcode: null,
          description: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        catalogItems.add(item);
      }

      // Add all items to catalog in batch
      await _itemsService.addMultipleItems(catalogItems);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${catalogItems.length} items to your catalog!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Mark onboarding as complete and navigate to home
      if (mounted) {
        context.read<AuthProvider>().completeOnboarding();
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
          ),
          (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add items: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
