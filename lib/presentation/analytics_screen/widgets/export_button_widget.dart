import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExportButtonWidget extends StatelessWidget {
  final VoidCallback onExport;

  const ExportButtonWidget({
    Key? key,
    required this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: CustomIconWidget(
        iconName: 'file_download',
        size: 24,
        color: theme.colorScheme.onSurface,
      ),
      tooltip: 'Export Data',
      color: theme.colorScheme.surface,
      elevation: theme.cardTheme.elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'csv',
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'table_view',
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              SizedBox(width: 3.w),
              Text(
                'Export as CSV',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'picture_as_pdf',
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              SizedBox(width: 3.w),
              Text(
                'Export as PDF',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'share',
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              SizedBox(width: 3.w),
              Text(
                'Share Report',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'csv':
            _showExportDialog(context, 'CSV', 'Exporting data as CSV file...');
            break;
          case 'pdf':
            _showExportDialog(context, 'PDF', 'Generating PDF report...');
            break;
          case 'share':
            _showShareDialog(context);
            break;
        }
      },
    );
  }

  void _showExportDialog(BuildContext context, String format, String message) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 3.h),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Simulate export process
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                size: 20,
                color: AppTheme.getSuccessColor(
                    theme.brightness == Brightness.light),
              ),
              SizedBox(width: 2.w),
              Text('$format export completed successfully'),
            ],
          ),
          backgroundColor: theme.colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    });
  }

  void _showShareDialog(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Analytics Report',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 3.h),
              _buildShareOption(
                context,
                'Email',
                'email',
                'Send via email',
              ),
              _buildShareOption(
                context,
                'Messages',
                'message',
                'Send via messages',
              ),
              _buildShareOption(
                context,
                'Copy Link',
                'link',
                'Copy shareable link',
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String title,
    String iconName,
    String subtitle,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        size: 24,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title sharing functionality coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
