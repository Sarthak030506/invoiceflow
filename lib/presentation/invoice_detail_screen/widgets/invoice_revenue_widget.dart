import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/invoice_model.dart';
import '../../../core/app_export.dart';

class InvoiceRevenueWidget extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceRevenueWidget({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      color: theme.colorScheme.surface,
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'attach_money',
              color: AppTheme.getSuccessColor(!isDark),
              size: 32,
            ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '₹${invoice.revenue.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.getSuccessColor(!isDark),
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
}
