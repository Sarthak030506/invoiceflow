import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../widgets/blurred_modal.dart';
import '../widgets/primary_button.dart';
import '../widgets/feedback_animations.dart';
import '../utils/haptic_feedback_util.dart';

class CustomerDueEditDialog {
  static Future<bool?> show(
    BuildContext context,
    CustomerModel customer,
    double currentDue, {
    Function()? onUpdated,
  }) {
    final TextEditingController controller = TextEditingController(
      text: currentDue.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();
    final customerService = CustomerService.instance;

    return BlurredModal.show(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Due Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Customer: ${customer.name}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'New Due Amount',
                prefixText: '₹',
                hintText: '0.00',
                helperText: 'Current due: ₹${currentDue.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount < 0) {
                  return 'Amount cannot be negative';
                }
                if (amount > currentDue) {
                  return 'New amount cannot be greater than current due';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: PrimaryButton(
                    text: 'Update',
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newAmount = double.parse(controller.text);

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          await customerService.adjustOutstandingBalance(
                            customer.id,
                            newAmount,
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context, true); // Close dialog with success

                            FeedbackAnimations.showSuccess(
                              context,
                              message: 'Due updated: ₹${newAmount.toStringAsFixed(2)}',
                            );
                            HapticFeedbackUtil.success();

                            // Call refresh callback
                            if (onUpdated != null) {
                              onUpdated();
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context, false); // Close dialog

                            FeedbackAnimations.showError(
                              context,
                              message: 'Update failed: ${e.toString()}',
                            );
                            HapticFeedbackUtil.error();
                          }
                        }
                      }
                    },
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
