import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class RecordPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final double alreadyPaid;
  final String currentPaymentMethod;

  const RecordPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.alreadyPaid,
    required this.currentPaymentMethod,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  late TextEditingController _amountController;
  String _selectedPaymentMethod = 'Cash';
  String? _errorText;

  double get remainingAmount => widget.totalAmount - widget.alreadyPaid;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.currentPaymentMethod;
    // Pre-fill with remaining amount
    _amountController = TextEditingController(
      text: remainingAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      setState(() {
        _errorText = 'Please enter a valid amount';
      });
      return;
    }

    if (amount > remainingAmount) {
      setState(() {
        _errorText = 'Amount cannot exceed remaining balance (₹${remainingAmount.toStringAsFixed(2)})';
      });
      return;
    }

    // Return the payment details
    Navigator.of(context).pop({
      'amount': amount,
      'paymentMethod': _selectedPaymentMethod,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment,
              color: Colors.green.shade600,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Record Payment',
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
            // Payment Summary Card
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
                    'Total Amount',
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    Colors.black87,
                  ),
                  SizedBox(height: 1.h),
                  _buildSummaryRow(
                    'Already Paid',
                    '₹${widget.alreadyPaid.toStringAsFixed(2)}',
                    Colors.grey.shade600,
                  ),
                  Divider(height: 2.h, thickness: 1),
                  _buildSummaryRow(
                    'Remaining Balance',
                    '₹${remainingAmount.toStringAsFixed(2)}',
                    Colors.red.shade700,
                    bold: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Amount Input
            Text(
              'Payment Amount',
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
                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),

            SizedBox(height: 2.h),

            // Quick Amount Buttons
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildQuickAmountChip('25%', remainingAmount * 0.25),
                _buildQuickAmountChip('50%', remainingAmount * 0.50),
                _buildQuickAmountChip('75%', remainingAmount * 0.75),
                _buildQuickAmountChip('Full', remainingAmount),
              ],
            ),

            SizedBox(height: 3.h),

            // Payment Method
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  borderRadius: BorderRadius.circular(12),
                  items: ['Cash', 'Online', 'Cheque'].map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == 'Cash'
                                ? Icons.money
                                : method == 'Online'
                                    ? Icons.credit_card
                                    : Icons.receipt_long,
                            size: 20,
                            color: Colors.green.shade600,
                          ),
                          SizedBox(width: 2.w),
                          Text(method),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 20),
              SizedBox(width: 1.w),
              Text('Record Payment', style: TextStyle(fontSize: 14.sp)),
            ],
          ),
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
      backgroundColor: Colors.green.shade50,
      side: BorderSide(color: Colors.green.shade200),
      onPressed: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(2);
          _errorText = null;
        });
      },
    );
  }
}
