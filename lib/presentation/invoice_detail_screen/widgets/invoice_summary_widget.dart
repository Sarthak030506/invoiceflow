import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/invoice_model.dart';
import '../../../theme/app_theme.dart';

class InvoiceSummaryWidget extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isEditMode;
  final TextEditingController notesController;
  final TextEditingController taxRateController;
  final List<Map<String, dynamic>> editedItems;

  const InvoiceSummaryWidget({
    super.key,
    required this.invoice,
    required this.isEditMode,
    required this.notesController,
    required this.taxRateController,
    required this.editedItems,
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
              "Summary",
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),

            SizedBox(height: 2.h),

            // Subtotal
            _buildSummaryRow(
              "Subtotal",
              "₹${_calculateSubtotal().toStringAsFixed(2)}",
              isTotal: false,
            ),

            SizedBox(height: 1.h),

            // Tax
            _buildTaxRow(),

            SizedBox(height: 1.h),

            // Divider
            Divider(
              color: AppTheme.lightTheme.dividerColor,
              thickness: 1,
            ),

            SizedBox(height: 1.h),

            // Total
            _buildSummaryRow(
              "Total",
              "₹${_calculateTotal().toStringAsFixed(2)}",
              isTotal: true,
            ),

            if (isEditMode) ...[
              SizedBox(height: 2.h),
              _buildEditableFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )
              : AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTheme.financialDataStyle(isLight: true, fontSize: 18)
                  .copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.primary,
                )
              : AppTheme.financialDataStyle(isLight: true, fontSize: 16),
        ),
      ],
    );
  }

  double _calculateSubtotal() {
    if (isEditMode) {
      return editedItems.fold(0.0, (sum, item) {
        final quantity = item['quantity'] as int? ?? 1;
        final price = item['price'] as double? ?? 0.0;
        return sum + (quantity * price);
      });
    } else {
      return invoice.subtotal;
    }
  }
  
  double _calculateTaxAmount() {
    final taxRate = double.tryParse(taxRateController.text) ?? 0.0;
    return _calculateSubtotal() * taxRate / 100;
  }
  
  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTaxAmount();
  }

  Widget _buildTaxRow() {
    final taxRate = isEditMode 
        ? double.tryParse(taxRateController.text) ?? 0.0 
        : invoice.taxRate;
    
    final taxAmount = isEditMode 
        ? _calculateTaxAmount() 
        : invoice.taxAmount;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tax (${taxRate.toStringAsFixed(1)}%)",
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        Text(
          "₹${taxAmount.toStringAsFixed(2)}",
          style: AppTheme.financialDataStyle(isLight: true, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      children: [
        Divider(
          color: AppTheme.lightTheme.dividerColor,
          thickness: 1,
        ),

        SizedBox(height: 2.h),

        Text(
          "Tax Settings",
          style: AppTheme.lightTheme.textTheme.titleSmall,
        ),

        SizedBox(height: 1.h),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: taxRateController,
                decoration: const InputDecoration(
                  labelText: "Tax Rate (%)",
                  isDense: true,
                  suffixText: "%",
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: AppTheme.lightTheme.dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tax Amount",
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                    Text(
                      "₹${_calculateTaxAmount().toStringAsFixed(2)}",
                      style: AppTheme.financialDataStyle(
                          isLight: true, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Additional fields
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: "Notes (Optional)",
            isDense: true,
          ),
          style: AppTheme.lightTheme.textTheme.bodyMedium,
          maxLines: 2,
        ),

        SizedBox(height: 1.h),

        TextFormField(
          decoration: const InputDecoration(
            labelText: "Terms & Conditions (Optional)",
            isDense: true,
          ),
          style: AppTheme.lightTheme.textTheme.bodyMedium,
          maxLines: 2,
        ),
      ],
    );
  }
}
