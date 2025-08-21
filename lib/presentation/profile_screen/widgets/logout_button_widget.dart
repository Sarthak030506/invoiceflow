import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LogoutButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorLight,
          foregroundColor: AppTheme.onErrorLight,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: AppTheme.onErrorLight,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              'Logout',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.onErrorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
