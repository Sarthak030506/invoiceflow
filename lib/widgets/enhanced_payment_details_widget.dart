import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class EnhancedPaymentDetailsWidget extends StatefulWidget {
  final double totalAmount;
  final String invoiceType;
  final double pendingRefundAmount;
  final Function(double amountPaid, String paymentMethod, String invoiceNumber, DateTime invoiceDate) onPaymentDetailsSubmitted;

  const EnhancedPaymentDetailsWidget({
    Key? key,
    required this.totalAmount,
    required this.invoiceType,
    this.pendingRefundAmount = 0.0,
    required this.onPaymentDetailsSubmitted,
  }) : super(key: key);

  @override
  State<EnhancedPaymentDetailsWidget> createState() => _EnhancedPaymentDetailsWidgetState();
}

class _EnhancedPaymentDetailsWidgetState extends State<EnhancedPaymentDetailsWidget> {
  late TextEditingController _amountPaidController;
  late TextEditingController _invoiceNumberController;
  String _selectedPaymentMethod = 'Cash';
  double _remainingAmount = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingInvoiceNumber = false;
  bool _isValidatingInvoiceNumber = false;
  bool _invoiceNumberExists = false;

  final List<String> _paymentMethods = ['Cash', 'Online', 'Cheque'];
  final FirestoreService _firestoreService = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    // Set default amount paid as adjusted total (after refund deduction)
    final adjustedTotal = widget.totalAmount - widget.pendingRefundAmount;
    _amountPaidController = TextEditingController(text: adjustedTotal.toStringAsFixed(2));
    _invoiceNumberController = TextEditingController();
    _calculateRemainingAmount();
    _generateInitialInvoiceNumber();
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _generateInitialInvoiceNumber() async {
    setState(() {
      _isLoadingInvoiceNumber = true;
    });

    try {
      final nextInvoiceNumber = await _firestoreService.generateNextInvoiceNumber();
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = nextInvoiceNumber;
          _isLoadingInvoiceNumber = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch}';
          _isLoadingInvoiceNumber = false;
        });
      }
    }
  }

  Future<void> _validateInvoiceNumber(String invoiceNumber) async {
    if (invoiceNumber.trim().isEmpty) {
      setState(() {
        _invoiceNumberExists = false;
      });
      return;
    }

    setState(() {
      _isValidatingInvoiceNumber = true;
    });

    try {
      final exists = await _firestoreService.isInvoiceNumberExists(invoiceNumber.trim());
      if (mounted) {
        setState(() {
          _invoiceNumberExists = exists;
          _isValidatingInvoiceNumber = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invoiceNumberExists = false;
          _isValidatingInvoiceNumber = false;
        });
      }
    }
  }

  void _calculateRemainingAmount() {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    // Adjust total amount by pending refund for calculations
    final adjustedTotal = widget.totalAmount - widget.pendingRefundAmount;
    setState(() {
      _remainingAmount = adjustedTotal - amountPaid;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'Select Invoice Date',
      confirmText: 'SELECT',
      cancelText: 'CANCEL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.invoiceType == 'sales' ? Colors.blue : Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
            'Invoice & Payment Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 2.h),

          // Invoice Number Input
          Text(
            'Invoice Number',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _invoiceNumberController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              suffixIcon: _isLoadingInvoiceNumber
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: EdgeInsets.all(3.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : _isValidatingInvoiceNumber
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: EdgeInsets.all(3.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        )
                      : _invoiceNumberExists
                          ? Icon(Icons.error, color: Colors.red)
                          : _invoiceNumberController.text.isNotEmpty
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : null,
              errorText: _invoiceNumberExists ? 'Invoice number already exists' : null,
            ),
            onChanged: (value) {
              // Debounce validation
              Future.delayed(Duration(milliseconds: 500), () {
                if (_invoiceNumberController.text == value) {
                  _validateInvoiceNumber(value);
                }
              });
            },
          ),
          SizedBox(height: 2.h),

          // Invoice Date Selection
          Text(
            'Invoice Date',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          InkWell(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  Icon(Icons.calendar_today, color: primaryColor, size: 5.w),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Original Total Amount Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice Total:',
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

          // Pending Refund Adjustment (if applicable)
          if (widget.pendingRefundAmount > 0) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 4.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Pending Refund:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '-₹${widget.pendingRefundAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Previous return credit will be adjusted',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount Payable:',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '₹${(widget.totalAmount - widget.pendingRefundAmount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ],
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
              onPressed: _isLoadingInvoiceNumber || _isValidatingInvoiceNumber || _invoiceNumberExists || _invoiceNumberController.text.trim().isEmpty
                  ? null
                  : () {
                      // Validate amount paid
                      final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
                      if (amountPaid < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Amount paid cannot be negative')),
                        );
                        return;
                      }

                      // Validate invoice number
                      final invoiceNumber = _invoiceNumberController.text.trim();
                      if (invoiceNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter an invoice number')),
                        );
                        return;
                      }

                      // Prevent overpayments - amount paid cannot exceed total
                      final adjustedTotal = widget.totalAmount - widget.pendingRefundAmount;
                      if (amountPaid > adjustedTotal) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Amount paid cannot exceed total amount (₹${adjustedTotal.toStringAsFixed(2)})'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Submit payment details
                      widget.onPaymentDetailsSubmitted(amountPaid, _selectedPaymentMethod, invoiceNumber, _selectedDate);
                    },
              child: Text(
                'Create Invoice',
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