import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/invoice_model.dart';

class InvoiceHeaderCardWidget extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isEditMode;
  final TextEditingController clientNameController;
  final TextEditingController invoiceDateController;

  const InvoiceHeaderCardWidget({
    super.key,
    required this.invoice,
    required this.isEditMode,
    required this.clientNameController,
    required this.invoiceDateController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.lightTheme.cardTheme.elevation,
      shape: AppTheme.lightTheme.cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Number and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Invoice Number",
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        invoice.invoiceNumber,
                        style: AppTheme.invoiceNumberStyle(
                            isLight: true, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius,
                    border: Border.all(
                      color: _getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    invoice.status,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Client Information
            _buildClientSection(),

            SizedBox(height: 3.h),

            // Date Information
            Row(
              children: [
                Expanded(
                  child: _buildDateField("Invoice Date", invoice.getFormattedDate()),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildDateField("Due Date", "N/A"),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Total Amount (Prominent)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.05),
                borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius,
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Total Amount",
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    "₹${_calculateTotal().toStringAsFixed(2)}",
                    style: AppTheme.financialDataStyle(
                        isLight: true, fontSize: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bill To",
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),
        SizedBox(height: 1.h),
        if (isEditMode)
          Column(
            children: [
              TextFormField(
                controller: clientNameController,
                decoration: const InputDecoration(
                  labelText: "Client Name",
                  isDense: true,
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              TextFormField(
                initialValue: "N/A",
                decoration: const InputDecoration(
                  labelText: "Client Email",
                  isDense: true,
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              TextFormField(
                initialValue: "N/A",
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Client Address",
                  isDense: true,
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.clientName,
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 0.5.h),
              Text(
                "N/A",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "N/A",
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateField(String label, String? value) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
          SizedBox(height: 0.5.h),
          if (isEditMode && label == "Invoice Date")
            TextFormField(
              controller: invoiceDateController,
              decoration: InputDecoration(
                isDense: true,
                suffixIcon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              readOnly: true,
              onTap: () async {
                // Show date picker
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: invoice.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
              if (picked != null) {
                invoiceDateController.text = 
                    "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
              }
            },
          )
        else if (isEditMode)
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              isDense: true,
              suffixIcon: CustomIconWidget(
                iconName: 'calendar_today',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
            ),
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            readOnly: true,
            onTap: () {
              // Date picker would be implemented here
            },
          )
        else
          Text(
            _formatDate(value),
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor() {
    final status = invoice.status;
    switch (status.toLowerCase()) {
      case 'paid':
        return AppTheme.getSuccessColor(true);
      case 'overdue':
        return AppTheme.lightTheme.colorScheme.error;
      case 'pending':
        return AppTheme.getWarningColor(true);
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }
  
  double _calculateTotal() {
    // In edit mode, we would need to calculate based on edited items
    // But since we don't have access to edited items here, we'll use the invoice total
    return invoice.total;
  }
}
