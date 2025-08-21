import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentInvoiceItemWidget extends StatelessWidget {
  final String invoiceNumber;
  final String date;
  final double amount;
  final String clientName;
  final String status;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onTap;
  final String invoiceType;
  final double amountPaid;
  final String paymentMethod;
  final bool modifiedFlag;
  final String? modifiedReason;
  final DateTime? modifiedAt;

  const RecentInvoiceItemWidget({
    super.key,
    required this.invoiceNumber,
    required this.date,
    required this.amount,
    required this.clientName,
    required this.status,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onTap,
    this.invoiceType = 'sales',
    this.amountPaid = 0.0,
    this.paymentMethod = 'Cash',
    this.modifiedFlag = false,
    this.modifiedReason,
    this.modifiedAt,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2.w),
        child: Card(
          elevation: Theme.of(context).cardTheme.elevation,
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(
              color: invoiceType == 'sales' ? Colors.blue : Colors.green,
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
                    onChanged: (_) => onTap?.call(),
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
                              'Invoice Number: $invoiceNumber',
                              style: AppTheme.invoiceNumberStyle(
                                isLight: !isDark,
                                fontSize: 14.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              if (modifiedFlag) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                                  margin: EdgeInsets.only(right: 1.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(1.w),
                                  ),
                                  child: Text(
                                    'MODIFIED',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                ),
                              ],
                              _buildStatusBadge(context, status, isDark),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                            decoration: BoxDecoration(
                              color: invoiceType == 'sales' 
                                ? Colors.blue.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Text(
                              invoiceType == 'sales' ? 'SALES' : 'PURCHASE',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: invoiceType == 'sales' ? Colors.blue : Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _formatDate(date),
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      if (clientName.isNotEmpty) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          clientName,
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (modifiedFlag && modifiedAt != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          'Modified on: ${DateFormat('MMM dd, yyyy').format(modifiedAt!)} - ${modifiedReason ?? 'Unknown reason'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            '₹${_formatCurrency(amount)}',
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
                          Row(
                            children: [
                              Text(
                                'Paid: ',
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                              Text(
                                '₹${_formatCurrency(amountPaid)}',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: amountPaid >= amount ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Text(
                              paymentMethod.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isDark) {
    final color = _getStatusColor(status, isDark);
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

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.getSuccessColor(isDark);
      case 'pending':
        return AppTheme.getWarningColor(isDark);
      case 'overdue':
        return isDark ? AppTheme.errorDark : AppTheme.errorLight;
      default:
        return isDark
            ? AppTheme.textSecondaryDark
            : AppTheme.textSecondaryLight;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(String rawDate) {
    try {
      final dateTime = DateFormat('yyyy-MM-dd').parse(rawDate);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (_) {
      return rawDate; // fallback
    }
  }
}
