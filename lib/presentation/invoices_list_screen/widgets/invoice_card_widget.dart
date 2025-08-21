import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

import '../../../models/invoice_model.dart';

class InvoiceCardWidget extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const InvoiceCardWidget({
    Key? key,
    required this.invoice,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Dismissible(
        key: Key(invoice.id as String),
        background: _buildSwipeBackground(isLeftSwipe: false),
        secondaryBackground: _buildSwipeBackground(isLeftSwipe: true),
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            // Edit action
            onEdit();
          } else if (direction == DismissDirection.endToStart) {
            // Delete action
            _showDeleteConfirmation(context);
          }
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await _showDeleteConfirmation(context);
          }
          return false;
        },
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Card(
            elevation: Theme.of(context).cardTheme.elevation,
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
              side: BorderSide(
                color: invoice.invoiceType == 'sales' ? Colors.blue : Colors.green,
                width: 2,
              ),
            ),
            margin: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  if (isMultiSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap,
                      activeColor: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    SizedBox(width: 3.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Invoice Number: ${invoice.invoiceNumber}',
                                style: AppTheme.invoiceNumberStyle(
                                  isLight: true,
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                if (invoice.modifiedFlag) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                                    margin: EdgeInsets.only(right: 1.w),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(1.w),
                                    ),
                                    child: Text(
                                      'MODIFIED',
                                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 8.sp,
                                      ),
                                    ),
                                  ),
                                ],
                                _buildStatusBadge(context, invoice.status as String),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(invoice.date as DateTime),
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                              decoration: BoxDecoration(
                                color: invoice.invoiceType == 'sales' 
                                  ? Colors.blue.withOpacity(0.1) 
                                  : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                invoice.invoiceType == 'sales' ? 'SALES' : 'PURCHASE',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: invoice.invoiceType == 'sales' ? Colors.blue : Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (invoice.clientName != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            invoice.clientName as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (invoice.modifiedFlag && invoice.modifiedAt != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            'Modified on: ${DateFormat('MMM dd, yyyy').format(invoice.modifiedAt!)} - ${invoice.modifiedReason ?? 'Unknown reason'}',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontSize: 10.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                            Text(
                              '₹${invoice.total.toStringAsFixed(2)}',
                              style: AppTheme.financialDataStyle(
                                isLight: true,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                invoice.paymentStatusDisplay,
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: _getPaymentStatusColor(invoice.paymentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                invoice.paymentMethod.toUpperCase(),
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMultiSelectMode) ...[
                    SizedBox(width: 3.w),
                    CustomIconWidget(
                      iconName: 'chevron_right',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(1.w),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.getSuccessColor(false);
      case 'pending':
        return AppTheme.getWarningColor(false);
      case 'overdue':
        return AppTheme.errorLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  Widget _buildSwipeBackground({required bool isLeftSwipe}) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: isLeftSwipe
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isLeftSwipe ? 'delete' : 'edit',
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                isLeftSwipe ? 'Delete' : 'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Invoice',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Delete',
            onPressed: () {
              Navigator.pop(context, true);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
