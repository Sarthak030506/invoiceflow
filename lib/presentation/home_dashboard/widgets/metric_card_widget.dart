import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MetricCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final double change;
  final String icon;
  final VoidCallback? onTap;

  const MetricCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositive = change >= 0;

    return FluidAnimations.createTapFeedback(
      onTap: onTap ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? (isDark ? AppTheme.shadowDark : AppTheme.shadowLight),
              blurRadius: Theme.of(context).cardTheme.elevation ?? 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: CustomIconWidget(
                    iconName: icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 6.w,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppTheme.getSuccessColor(isDark)
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: isPositive ? 'trending_up' : 'trending_down',
                        color: isPositive
                            ? AppTheme.getSuccessColor(isDark)
                            : Theme.of(context).colorScheme.error,
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${change.abs().toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPositive
                                  ? AppTheme.getSuccessColor(isDark)
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 24.sp,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
