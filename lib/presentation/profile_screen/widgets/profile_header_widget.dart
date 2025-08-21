import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final bool isEmailVerified;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.isEmailVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          // Profile Image
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.primaryColor,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: profileImageUrl,
                width: 25.w,
                height: 25.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // User Name
          Text(
            userName,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          // Email with verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  userEmail,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEmailVerified) ...[
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'verified',
                  color: AppTheme.getSuccessColor(true),
                  size: 16,
                ),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          // Member since info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Member since March 2024',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
