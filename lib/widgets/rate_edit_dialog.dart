import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../models/catalog_item.dart';
import '../services/catalog_service.dart';

class RateEditDialog extends StatefulWidget {
  final CatalogItem item;
  final Function()? onRateUpdated;

  const RateEditDialog({
    Key? key,
    required this.item,
    this.onRateUpdated,
  }) : super(key: key);

  @override
  State<RateEditDialog> createState() => _RateEditDialogState();

  static Future<bool?> show(BuildContext context, CatalogItem item, {Function()? onRateUpdated}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RateEditDialog(
        item: item,
        onRateUpdated: onRateUpdated,
      ),
    );
  }
}

class _RateEditDialogState extends State<RateEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  final CatalogService _catalogService = CatalogService.instance;
  bool _isLoading = false;
  bool _hasCustomRate = false;
  double _defaultRate = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _rateController = TextEditingController(text: widget.item.rate.toStringAsFixed(2));
    _loadRateInfo();
  }

  Future<void> _loadRateInfo() async {
    _hasCustomRate = await _catalogService.hasCustomRate(widget.item.id);
    _defaultRate = _catalogService.getDefaultRate(widget.item.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _updateRate() async {
    final newName = _nameController.text.trim();
    final newRateText = _rateController.text.trim();
    final newRate = double.tryParse(newRateText);

    // Validation
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newRate == null || newRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _catalogService.updateItemNameAndRate(widget.item.id, newName, newRate);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Callback
      if (widget.onRateUpdated != null) {
        widget.onRateUpdated!();
      }

      // Close dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _catalogService.resetItemRate(widget.item.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rate reset to default: ₹${_defaultRate.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );

      // Callback
      if (widget.onRateUpdated != null) {
        widget.onRateUpdated!();
      }

      // Close dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting rate: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Edit Item',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Current rate info
          if (_hasCustomRate)
            Container(
              padding: EdgeInsets.all(2.w),
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 4.w, color: Colors.blue.shade700),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom rate active',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Default: ₹${_defaultRate.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Name input
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Item Name',
              hintText: 'Enter item name',
              prefixIcon: Icon(Icons.inventory_2, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),

          SizedBox(height: 2.h),

          // Rate input
          TextField(
            controller: _rateController,
            enabled: !_isLoading,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Rate (₹)',
              hintText: 'Enter rate',
              prefixIcon: Icon(Icons.currency_rupee, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _updateRate(),
          ),

          SizedBox(height: 1.h),

          // Info text
          Text(
            'This will update the item for all future invoices',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // Reset button (only show if has custom rate)
        if (_hasCustomRate)
          TextButton.icon(
            onPressed: _isLoading ? null : _resetToDefault,
            icon: Icon(Icons.refresh, size: 4.w),
            label: const Text('Reset to Default'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          )
        else
          const SizedBox.shrink(),

        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),

        // Update button
        ElevatedButton(
          onPressed: _isLoading ? null : _updateRate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
