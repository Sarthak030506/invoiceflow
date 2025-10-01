import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/return_model.dart';

class ReturnDetailScreen extends StatelessWidget {
  final ReturnModel returnModel;

  const ReturnDetailScreen({
    Key? key,
    required this.returnModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSalesReturn = returnModel.returnType == 'sales';
    final color = isSalesReturn ? Colors.orange : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(returnModel.returnNumber),
        actions: [
          if (returnModel.isApplied)
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Applied',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              color: color.shade50,
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_return,
                    size: 64,
                    color: color.shade600,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${isSalesReturn ? 'Sales' : 'Purchase'} Return',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    returnModel.returnNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: color.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Return Information
                  _buildSectionCard(
                    context,
                    'Return Information',
                    [
                      _buildDetailRow('Return Number:', returnModel.returnNumber),
                      _buildDetailRow('Return Date:', _formatDate(returnModel.returnDate)),
                      _buildDetailRow('Status:', returnModel.isApplied ? 'Applied' : 'Pending',
                          valueColor: returnModel.isApplied ? Colors.green.shade700 : Colors.orange.shade700),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Invoice Information
                  _buildSectionCard(
                    context,
                    'Original Invoice',
                    [
                      _buildDetailRow('Invoice Number:', returnModel.invoiceNumber),
                      _buildDetailRow('Invoice Date:', _formatDate(returnModel.invoiceDate)),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Customer Information
                  _buildSectionCard(
                    context,
                    'Customer Information',
                    [
                      _buildDetailRow('Name:', returnModel.customerName),
                      if (returnModel.customerPhone != null)
                        _buildDetailRow('Phone:', returnModel.customerPhone!),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Return Reason
                  _buildSectionCard(
                    context,
                    'Return Details',
                    [
                      _buildDetailRow('Reason:', returnModel.returnReason),
                      if (returnModel.notes != null && returnModel.notes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 1.h),
                            Text(
                              'Notes:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              returnModel.notes!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Items Returned
                  _buildSectionCard(
                    context,
                    'Items Returned',
                    [
                      ...returnModel.items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quantity:',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Price per unit:',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 2.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.totalValue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: color.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Financial Summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.shade200, width: 2),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          Text(
                            'Financial Summary',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Divider(height: 3.h),
                          _buildSummaryRow(
                            'Total Return Value:',
                            '₹${returnModel.totalReturnValue.toStringAsFixed(2)}',
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(height: 1.h),
                          _buildSummaryRow(
                            isSalesReturn ? 'Refund Amount:' : 'Expected Amount:',
                            '₹${returnModel.refundAmount.toStringAsFixed(2)}',
                            color: Colors.green.shade700,
                            isLarge: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
            ),
            SizedBox(height: 2.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16.sp : 14.sp,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
