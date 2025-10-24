import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InvoiceActionButtonsWidget extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onRecordPayment;
  final VoidCallback onDownloadPdf;
  final VoidCallback? onDelete;
  final bool isMarkingAsPaid;
  final bool hasRemainingBalance;

  const InvoiceActionButtonsWidget({
    super.key,
    required this.onShare,
    required this.onMarkAsPaid,
    required this.onRecordPayment,
    required this.onDownloadPdf,
    this.onDelete,
    this.isMarkingAsPaid = false,
    this.hasRemainingBalance = true,
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
                    onPressed: onShare,
                    icon: Icon(Icons.share, size: 20),
                    label: Text("Share PDF"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasRemainingBalance
                        ? (isMarkingAsPaid ? null : onRecordPayment)
                        : null,
                    icon: isMarkingAsPaid
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            hasRemainingBalance ? Icons.payment : Icons.check_circle,
                            size: 20,
                          ),
                    label: Text(
                      isMarkingAsPaid
                          ? "Processing..."
                          : hasRemainingBalance
                              ? "Record Payment"
                              : "Paid in Full",
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      backgroundColor: hasRemainingBalance
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Quick Mark as Paid button (only show if there's remaining balance)
            if (hasRemainingBalance && !isMarkingAsPaid) ...[
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMarkAsPaid,
                  icon: Icon(Icons.check_circle_outline, size: 18),
                  label: Text("Mark as Fully Paid (Quick)"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    side: BorderSide(color: Colors.green.shade600, width: 1.5),
                    foregroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 2.h),

            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownloadPdf,
                    icon: Icon(Icons.download, size: 20),
                    label: Text("Download PDF"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                      foregroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
