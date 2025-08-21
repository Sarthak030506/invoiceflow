import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InvoiceActionButtonsWidget extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDuplicate;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onDelete;

  const InvoiceActionButtonsWidget({
    super.key,
    required this.onEdit,
    required this.onShare,
    required this.onDuplicate,
    this.onMarkAsPaid,
    this.onDownloadPdf,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Actions",
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),

            SizedBox(height: 2.h),

            // Primary Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: CustomIconWidget(
                      iconName: 'edit',
                      color: AppTheme.lightTheme.elevatedButtonTheme.style
                              ?.foregroundColor
                              ?.resolve({}) ??
                          Colors.white,
                      size: 18,
                    ),
                    label: Text("Edit Invoice"),
                    style: AppTheme.lightTheme.elevatedButtonTheme.style,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text("Share PDF"),
                    style: AppTheme.lightTheme.outlinedButtonTheme.style,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDuplicate,
                    icon: CustomIconWidget(
                      iconName: 'content_copy',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text("Duplicate"),
                    style: AppTheme.lightTheme.textButtonTheme.style,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete ?? () {
                      _showDeleteConfirmation(context);
                    },
                    icon: CustomIconWidget(
                      iconName: 'delete',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 18,
                    ),
                    label: Text(
                      "Delete",
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                    style: AppTheme.lightTheme.textButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStateProperty.all(
                        AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Additional Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            _buildQuickActionChip(
              "Mark as Paid",
              'check_circle',
              AppTheme.getSuccessColor(true),
              onMarkAsPaid ?? () {},
            ),
            _buildQuickActionChip(
              "Send Reminder",
              'email',
              AppTheme.getWarningColor(true),
              () {
                // Send reminder functionality
              },
            ),
            _buildQuickActionChip(
              "Download PDF",
              'download',
              AppTheme.lightTheme.colorScheme.primary,
              onDownloadPdf ?? () {},
            ),
            _buildQuickActionChip(
              "Print",
              'print',
              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              () {
                // Print functionality
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    String label,
    String iconName,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Delete Invoice",
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this invoice? This action cannot be undone.",
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Delete invoice functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                foregroundColor: AppTheme.lightTheme.colorScheme.onError,
              ),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
