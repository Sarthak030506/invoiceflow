import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InvoiceItemsTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool isEditMode;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const InvoiceItemsTableWidget({
    super.key,
    required this.items,
    required this.isEditMode,
    required this.onItemsChanged,
  });
  
  @override
  State<InvoiceItemsTableWidget> createState() => _InvoiceItemsTableWidgetState();
}

class _InvoiceItemsTableWidgetState extends State<InvoiceItemsTableWidget> {

  // Local copy of items for editing
  late List<Map<String, dynamic>> _localItems;
  
  @override
  void initState() {
    super.initState();
    _localItems = List<Map<String, dynamic>>.from(widget.items);
  }
  
  @override
  void didUpdateWidget(InvoiceItemsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _localItems = List<Map<String, dynamic>>.from(widget.items);
    }
  }
  
  void _updateItem(int index, String field, dynamic value) {
    setState(() {
      _localItems[index][field] = value;
      
      // Update total price if quantity or price changes
      if (field == 'quantity' || field == 'price') {
        final quantity = _localItems[index]['quantity'] as int? ?? 1;
        final price = _localItems[index]['price'] as double? ?? 0.0;
        _localItems[index]['totalPrice'] = quantity * price;
      }
      
      // Notify parent about changes
      widget.onItemsChanged(_localItems);
    });
  }
  
  void _addNewItem() {
    setState(() {
      _localItems.add({
        'name': 'New Item',
        'description': '',
        'quantity': 1,
        'price': 0.0,
        'totalPrice': 0.0,
      });
      widget.onItemsChanged(_localItems);
    });
  }
  
  void _removeItem(int index) {
    setState(() {
      _localItems.removeAt(index);
      widget.onItemsChanged(_localItems);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Items",
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                if (widget.isEditMode)
                  TextButton.icon(
                    onPressed: _addNewItem,
                    icon: CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 16,
                    ),
                    label: Text(
                      "Add Item",
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 2.h),

            // Table Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Item",
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Qty",
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Rate",
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Amount",
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Table Body
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.lightTheme.dividerColor,
                  width: 1,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: _localItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      // Use RepaintBoundary for each row to optimize rendering
                      return RepaintBoundary(
                        child: _buildItemRow(item, index),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.transparent
            : AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        border: index < _localItems.length - 1
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.lightTheme.dividerColor,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: widget.isEditMode ? _buildEditableRow(item, index) : _buildDisplayRow(item),
    );
  }

  Widget _buildDisplayRow(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Name and Description
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item["name"] ?? "N/A",
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item["description"] != null && item["description"].isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Text(
                    item["description"],
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        // Quantity
        Expanded(
          flex: 1,
          child: Text(
            "${item["quantity"] ?? 0}",
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),

        // Unit Price
        Expanded(
          flex: 2,
          child: Text(
            "₹${(item["price"] as double? ?? 0.0).toStringAsFixed(2)}",
            style: AppTheme.financialDataStyle(isLight: true, fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),

        // Line Total
        Expanded(
          flex: 2,
          child: Text(
            "₹${(item["totalPrice"] as double? ?? 0.0).toStringAsFixed(2)}",
            style: AppTheme.financialDataStyle(isLight: true, fontSize: 14)
                .copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(Map<String, dynamic> item, int index) {
    // Create controllers with current values
    final nameController = TextEditingController(text: item["name"] ?? '');
    final descController = TextEditingController(text: item["description"] ?? '');
    final qtyController = TextEditingController(text: "${item["quantity"] ?? 1}");
    final priceController = TextEditingController(text: "${item["price"] ?? 0.0}");
    
    return Column(
      children: [
        // Item Name
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Item Name",
            isDense: true,
          ),
          style: AppTheme.lightTheme.textTheme.bodyMedium,
          onChanged: (value) => _updateItem(index, 'name', value),
        ),

        SizedBox(height: 1.h),

        // Description
        TextFormField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: "Description",
            isDense: true,
          ),
          style: AppTheme.lightTheme.textTheme.bodySmall,
          onChanged: (value) => _updateItem(index, 'description', value),
        ),

        SizedBox(height: 1.h),

        // Quantity, Unit Price, Total Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: "Qty",
                  isDense: true,
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = int.tryParse(value) ?? 1;
                  _updateItem(index, 'quantity', qty);
                },
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: "Price",
                  isDense: true,
                  prefixText: "₹",
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0.0;
                  _updateItem(index, 'price', price);
                },
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "₹${(item["totalPrice"] as double? ?? (item["price"] as double? ?? 0.0) * (item["quantity"] as int? ?? 1)).toStringAsFixed(2)}",
                  style:
                      AppTheme.financialDataStyle(isLight: true, fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),

        // Delete button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _removeItem(index),
            icon: CustomIconWidget(
              iconName: 'delete',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 16,
            ),
            label: Text(
              "Remove",
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.error,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
