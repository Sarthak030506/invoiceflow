import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final bool isEmailVerified;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.isEmailVerified,
  });

  /// Generate user initials from name
  String _getUserInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }

  /// Generate color from name for consistent avatar background
  Color _getAvatarColor(String name) {
    final colors = [
      Color(0xFF1976D2), // Blue
      Color(0xFF388E3C), // Green
      Color(0xFFD32F2F), // Red
      Color(0xFFF57C00), // Orange
      Color(0xFF7B1FA2), // Purple
      Color(0xFF0097A7), // Cyan
      Color(0xFFC2185B), // Pink
      Color(0xFF5D4037), // Brown
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

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
          // Profile Image or Initials Avatar
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
              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: profileImageUrl!,
                      width: 25.w,
                      height: 25.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _getAvatarColor(userName),
                      child: Center(
                        child: Text(
                          _getUserInitials(userName),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
        ],
      ),
    );
  }
}
