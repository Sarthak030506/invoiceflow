import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/invoice_model.dart';
import '../../../services/edit_invoice_service.dart';
import '../../../widgets/app_loading_indicator.dart';

class EditInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;
  final Function(InvoiceModel) onInvoiceUpdated;

  const EditInvoiceDialog({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  State<EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  final EditInvoiceService _editService = EditInvoiceService.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _editReasonController = TextEditingController();

  List<EditableInvoiceItem> _items = [];
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.invoice.notes ?? '';
    _amountPaidController.text = widget.invoice.amountPaid.toStringAsFixed(2);
    _selectedDate = widget.invoice.date;
    _paymentMethod = widget.invoice.paymentMethod;

    // Initialize editable items
    _items = widget.invoice.items
        .map((item) => EditableInvoiceItem(
              name: item.name,
              quantity: item.quantity.toDouble(),
              price: item.price.toDouble(),
            ))
        .toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountPaidController.dispose();
    _editReasonController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      FeedbackAnimations.showError(context, message: 'Add at least one item');
      return;
    }

    if (_editReasonController.text.trim().isEmpty) {
      FeedbackAnimations.showError(context, message: 'Please provide a reason for editing');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create new invoice with updated data
      final newInvoice = widget.invoice.copyWith(
        items: _items
            .map((item) => InvoiceItem(
                  name: item.name,
                  quantity: item.quantity.toInt(),
                  price: item.price.toDouble(),
                ))
            .toList(),
        date: _selectedDate,
        notes: _notesController.text.trim(),
        amountPaid: double.parse(_amountPaidController.text),
        paymentMethod: _paymentMethod,
      );

      // Validate if invoice can be edited
      final validationError = await _editService.validateInvoiceCanBeEdited(widget.invoice);
      if (validationError != null) {
        if (!mounted) return;
        FeedbackAnimations.showError(context, message: validationError);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Edit the invoice
      final result = await _editService.editInvoice(
        oldInvoice: widget.invoice,
        newInvoice: newInvoice,
        editReason: _editReasonController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.success && result.updatedInvoice != null) {
        // Show reconciliation info if payment status changed
        if (result.paymentReconciliation!.totalChanged) {
          await _showReconciliationDialog(result.paymentReconciliation!);
        }

        FeedbackAnimations.showSuccess(
          context,
          message: 'Invoice updated successfully',
        );
        HapticFeedbackUtil.success();

        Navigator.pop(context);
        widget.onInvoiceUpdated(result.updatedInvoice!);
      } else {
        FeedbackAnimations.showError(
          context,
          message: result.errorMessage ?? 'Failed to update invoice',
        );
        HapticFeedbackUtil.error();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      FeedbackAnimations.showError(
        context,
        message: 'Error: ${e.toString()}',
      );
      HapticFeedbackUtil.error();
    }
  }

  Future<void> _showReconciliationDialog(PaymentReconciliation reconciliation) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Status Changed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous Total: ₹${reconciliation.oldTotal.toStringAsFixed(2)}'),
            Text('New Total: ₹${reconciliation.newTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Amount Paid: ₹${reconciliation.amountPaid.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              reconciliation.statusMessage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: reconciliation.needsRefund
                    ? Colors.orange
                    : reconciliation.needsPayment
                        ? Colors.red
                        : Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        width: double.infinity,
        height: 90.h,
        padding: EdgeInsets.all(4.w),
        child: _isLoading
            ? const AppLoadingIndicator.centered(message: 'Updating invoice...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Invoice',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: 2.h),

                  // Form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // Edit Reason (Required)
                          TextFormField(
                            controller: _editReasonController,
                            decoration: InputDecoration(
                              labelText: 'Reason for Edit *',
                              hintText: 'e.g., Correcting quantity, Price adjustment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please provide a reason';
                              }
                              return null;
                            },
                            maxLines: 2,
                          ),
                          SizedBox(height: 2.h),

                          // Date
                          ListTile(
                            title: const Text('Invoice Date'),
                            subtitle: Text(_selectedDate.toString().split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            },
                          ),
                          SizedBox(height: 2.h),

                          // Items Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _addItem,
                                icon: Icon(Icons.add_circle, color: Colors.green),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),

                          // Items List
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildItemCard(item, index);
                          }).toList(),

                          SizedBox(height: 2.h),

                          // Payment Info
                          Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1.h),

                          TextFormField(
                            controller: _amountPaidController,
                            decoration: InputDecoration(
                              labelText: 'Amount Paid',
                              prefixText: '₹',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid amount';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 1.h),

                          DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Cash', 'Online', 'Cheque']
                                .map((method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _paymentMethod = value;
                                });
                              }
                            },
                          ),
                          SizedBox(height: 2.h),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 2.h),

                          // Total Display
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total:'),
                                    Text(
                                      '₹${_calculateTotal().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Update Invoice',
                          onPressed: _validateAndSave,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildItemCard(EditableInvoiceItem item, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _items.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toStringAsFixed(1),
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final qty = double.tryParse(value);
                      if (qty != null) {
                        setState(() {
                          item.quantity = qty;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    initialValue: item.price.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null) {
                        setState(() {
                          item.price = price;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    // For simplicity, this would show a dialog to select an item
    // For now, add a placeholder item
    setState(() {
      _items.add(EditableInvoiceItem(
        name: 'New Item',
        quantity: 1.0,
        price: 0.0,
      ));
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }
}

class EditableInvoiceItem {
  String name;
  double quantity;
  double price;

  EditableInvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
