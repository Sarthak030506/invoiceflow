import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class PaymentDetailsWidget extends StatefulWidget {
  final double totalAmount;
  final String invoiceType;
  final Function(double amountPaid, String paymentMethod) onPaymentDetailsSubmitted;

  const PaymentDetailsWidget({
    Key? key,
    required this.totalAmount,
    required this.invoiceType,
    required this.onPaymentDetailsSubmitted,
  }) : super(key: key);

  @override
  State<PaymentDetailsWidget> createState() => _PaymentDetailsWidgetState();
}

class _PaymentDetailsWidgetState extends State<PaymentDetailsWidget> {
  late TextEditingController _amountPaidController;
  String _selectedPaymentMethod = 'Cash';
  double _remainingAmount = 0;
  final List<String> _paymentMethods = ['Cash', 'Online', 'Cheque'];

  @override
  void initState() {
    super.initState();
    _amountPaidController = TextEditingController(text: widget.totalAmount.toString());
    _calculateRemainingAmount();
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  void _calculateRemainingAmount() {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    setState(() {
      _remainingAmount = widget.totalAmount - amountPaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.invoiceType == 'sales' ? Colors.blue : Colors.green;
    final String paymentLabel = widget.invoiceType == 'sales' 
        ? 'Amount Received from Customer' 
        : 'Amount Paid to Supplier';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Total Amount Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          
          // Amount Paid Input
          Text(
            paymentLabel,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _amountPaidController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            ),
            onChanged: (value) {
              _calculateRemainingAmount();
            },
          ),
          SizedBox(height: 2.h),
          
          // Payment Status Display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPaymentStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getPaymentStatusText(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: _getPaymentStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          
          // Payment Method Selection
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
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
          SizedBox(height: 3.h),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 5.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Validate amount paid
                final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
                if (amountPaid < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Amount paid cannot be negative')),
                  );
                  return;
                }
                
                // Allow overpayments but show warning
                if (amountPaid > widget.totalAmount) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Overpayment Detected'),
                      content: Text('The amount paid (₹${amountPaid.toStringAsFixed(2)}) exceeds the total amount (₹${widget.totalAmount.toStringAsFixed(2)}). This will result in a refund due of ₹${(amountPaid - widget.totalAmount).toStringAsFixed(2)}. Do you want to continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onPaymentDetailsSubmitted(amountPaid, _selectedPaymentMethod);
                          },
                          child: Text('Continue'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                
                // Submit payment details
                widget.onPaymentDetailsSubmitted(amountPaid, _selectedPaymentMethod);
              },
              child: Text(
                'Confirm Payment Details',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusText() {
    if (_remainingAmount.abs() < 0.01) {
      return "Paid in Full";
    } else if (_remainingAmount > 0) {
      return "Balance Due: ₹${_remainingAmount.toStringAsFixed(2)}";
    } else {
      return "Refund Due: ₹${(-_remainingAmount).toStringAsFixed(2)}";
    }
  }

  Color _getPaymentStatusColor() {
    if (_remainingAmount.abs() < 0.01) {
      return Colors.green;
    } else if (_remainingAmount > 0) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}