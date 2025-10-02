import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/invoice_model.dart';
import '../../../core/app_export.dart';

class InvoicePaymentInfoWidget extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoicePaymentInfoWidget({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: Check refund adjustment value
    print('DEBUG: Invoice refundAdjustment = ${invoice.refundAdjustment}');
    print('DEBUG: Invoice total = ${invoice.total}');
    print('DEBUG: Invoice adjustedTotal = ${invoice.adjustedTotal}');

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Payment details with refund adjustment
          if (invoice.refundAdjustment > 0) ...[
            _buildPaymentRow('Invoice Total', '₹${invoice.total.toStringAsFixed(2)}'),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.blue, size: 4.w),
                      SizedBox(width: 2.w),
                      Text(
                        'Refund Applied',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-₹${invoice.refundAdjustment.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0.5.h),
            Divider(thickness: 1),
            _buildPaymentRow('Total Amount', '₹${invoice.adjustedTotal.toStringAsFixed(2)}', isHighlighted: true),
          ] else
            _buildPaymentRow('Total Amount', '₹${invoice.total.toStringAsFixed(2)}'),

          _buildPaymentRow('Amount Paid', '₹${invoice.amountPaid.toStringAsFixed(2)}'),

          // Payment status with proper handling of overpayments
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(invoice.paymentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPaymentStatusColor(invoice.paymentStatus).withOpacity(0.3),
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
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  invoice.paymentStatusDisplay,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: _getPaymentStatusColor(invoice.paymentStatus),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted 
                  ? Colors.red 
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paidInFull:
        return Colors.green;
      case PaymentStatus.balanceDue:
        return Colors.orange;
      case PaymentStatus.refundDue:
        return Colors.blue;
    }
  }
}