import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../widgets/feedback_animations.dart';
import '../utils/haptic_feedback_util.dart';

class CustomerDueEditDialog extends StatefulWidget {
  final CustomerModel customer;
  final double currentDue;
  final Function()? onUpdated;

  const CustomerDueEditDialog({
    super.key,
    required this.customer,
    required this.currentDue,
    this.onUpdated,
  });

  static Future<bool?> show(
    BuildContext context,
    CustomerModel customer,
    double currentDue, {
    Function()? onUpdated,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomerDueEditDialog(
        customer: customer,
        currentDue: currentDue,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<CustomerDueEditDialog> createState() => _CustomerDueEditDialogState();
}

class _CustomerDueEditDialogState extends State<CustomerDueEditDialog> {
  late TextEditingController _amountController;
  String? _errorText;
  final customerService = CustomerService.instance;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current due amount
    _amountController = TextEditingController(
      text: widget.currentDue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount < 0) {
      setState(() {
        _errorText = 'Please enter a valid amount';
      });
      return;
    }

    if (amount > widget.currentDue) {
      setState(() {
        _errorText = 'Amount cannot exceed current due (₹${widget.currentDue.toStringAsFixed(2)})';
      });
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await customerService.adjustOutstandingBalance(
        widget.customer.id,
        amount,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context, true); // Close dialog with success

        FeedbackAnimations.showSuccess(
          context,
          message: 'Due updated: ₹${amount.toStringAsFixed(2)}',
        );
        HapticFeedbackUtil.success();

        // Call refresh callback
        if (widget.onUpdated != null) {
          widget.onUpdated!();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context, false); // Close dialog

        FeedbackAnimations.showError(
          context,
          message: 'Update failed: ${e.toString()}',
        );
        HapticFeedbackUtil.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newDueAmount = double.tryParse(_amountController.text) ?? widget.currentDue;
    final reduction = widget.currentDue - newDueAmount;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Edit Due Amount',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            Text(
              'Customer: ${widget.customer.name}',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),

            // Due Summary Card
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Current Due',
                    '₹${widget.currentDue.toStringAsFixed(2)}',
                    Colors.black87,
                  ),
                  SizedBox(height: 1.h),
                  _buildSummaryRow(
                    'New Due Amount',
                    '₹${newDueAmount.toStringAsFixed(2)}',
                    Colors.grey.shade600,
                  ),
                  Divider(height: 2.h, thickness: 1),
                  _buildSummaryRow(
                    'Reduction',
                    '₹${reduction.toStringAsFixed(2)}',
                    reduction >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    bold: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Amount Input
            Text(
              'New Due Amount',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.currency_rupee, size: 20),
                hintText: 'Enter amount',
                errorText: _errorText,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _errorText = null;
                });
              },
            ),

            SizedBox(height: 2.h),

            // Quick Amount Buttons
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildQuickAmountChip('25%', widget.currentDue * 0.25),
                _buildQuickAmountChip('50%', widget.currentDue * 0.50),
                _buildQuickAmountChip('75%', widget.currentDue * 0.75),
                _buildQuickAmountChip('Full', widget.currentDue),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 2.h),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 1.5.w),
                    Flexible(
                      child: Text(
                        'Update Due',
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
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(
        '$label (₹${amount.toStringAsFixed(0)})',
        style: TextStyle(fontSize: 11.sp),
      ),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      onPressed: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(2);
          _errorText = null;
        });
      },
    );
  }
}
