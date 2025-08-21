import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/invoice_model.dart';
import '../../../presentation/invoice_detail_screen/widgets/whatsapp_reminder_button.dart';

class CustomerInvoiceItem extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  final String shopName;
  
  const CustomerInvoiceItem({
    Key? key,
    required this.invoice,
    required this.onTap,
    required this.shopName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasRemainingAmount = invoice.remainingAmount > 0;
    
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    invoice.getFormattedDate(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 1.h),
              
              // Invoice amounts
              Row(
                children: [
                  Expanded(
                    child: _buildAmountInfo('Total', invoice.total),
                  ),
                  Expanded(
                    child: _buildAmountInfo('Paid', invoice.amountPaid),
                  ),
                  Expanded(
                    child: _buildAmountInfo(
                      'Remaining', 
                      invoice.remainingAmount,
                      isHighlighted: hasRemainingAmount,
                    ),
                  ),
                ],
              ),
              
              // WhatsApp reminder button for unpaid invoices
              if (hasRemainingAmount && invoice.invoiceType == 'sales')
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/invoice-detail-screen',
                          arguments: invoice,
                        );
                      },
                      icon: Icon(
                        Icons.message,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      label: Text(
                        'Send WhatsApp Reminder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp green color
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAmountInfo(String label, num amount, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}