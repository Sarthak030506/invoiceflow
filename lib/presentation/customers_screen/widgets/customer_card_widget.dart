import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/customer_model.dart';

class CustomerCardWidget extends StatelessWidget {
  final CustomerModel customer;
  final double outstandingBalance;
  final VoidCallback onTap;
  
  const CustomerCardWidget({
    Key? key,
    required this.customer,
    required this.outstandingBalance,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      color: Theme.of(context).cardColor,
      shape: Theme.of(context).cardTheme.shape,
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: AppTheme.lightTheme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (outstandingBalance > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.getWarningColor(true).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Due: ₹${outstandingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.getWarningColor(true),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 14.sp,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    customer.phoneNumber,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}