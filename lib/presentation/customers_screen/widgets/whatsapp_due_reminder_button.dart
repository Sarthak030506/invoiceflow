import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../constants/app_scaling.dart';
import '../../../models/customer_model.dart';
import '../../../models/invoice_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/app_export.dart';

class WhatsAppDueReminderButton extends StatefulWidget {
  final CustomerModel customer;
  final double totalDue;

  const WhatsAppDueReminderButton({
    Key? key,
    required this.customer,
    required this.totalDue,
  }) : super(key: key);

  @override
  State<WhatsAppDueReminderButton> createState() => _WhatsAppDueReminderButtonState();
}

class _WhatsAppDueReminderButtonState extends State<WhatsAppDueReminderButton> {
  bool _isGenerating = false;

  Future<void> _sendWhatsAppReminder(BuildContext context) async {
    if (widget.customer.phoneNumber.isEmpty) {
      FeedbackAnimations.showError(context, message: 'No phone number available');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      print('Fetching unpaid invoices for customer: ${widget.customer.name}');

      // Get all unpaid invoices for this customer
      final FirestoreService firestoreService = FirestoreService.instance;
      final List<InvoiceModel> allInvoices = await firestoreService.getInvoicesByCustomerId(widget.customer.id);

      // Filter unpaid invoices
      final List<InvoiceModel> unpaidInvoices = allInvoices.where((invoice) {
        final remaining = invoice.adjustedTotal - invoice.amountPaid;
        return remaining > 0.01; // Consider amounts > ₹0.01 as unpaid
      }).toList();

      if (unpaidInvoices.isEmpty) {
        print('No unpaid invoices found for customer');
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
          FeedbackAnimations.showError(context, message: 'No unpaid invoices found');
        }
        return;
      }

      print('Found ${unpaidInvoices.length} unpaid invoices, generating summary PDF');

      // Generate summary PDF
      final PdfService pdfService = PdfService.instance;
      final String pdfPath = await pdfService.getOutstandingInvoicesSummaryPdfPath(
        customerName: widget.customer.name,
        customerPhone: widget.customer.phoneNumber,
        unpaidInvoices: unpaidInvoices,
      );

      print('Summary PDF generated at: $pdfPath');

      final message = '''Hello ${widget.customer.name},

This is a friendly reminder regarding your outstanding balance.

Total Due: ₹${widget.totalDue.toStringAsFixed(2)}

Please find attached the detailed statement of your outstanding invoices.

Please arrange for the payment at your earliest convenience.

Thank you for your business!

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';

      // Format phone number
      String phoneNumber = widget.customer.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }
      if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
        phoneNumber = '91$phoneNumber';
      }

      print('Opening WhatsApp for number: $phoneNumber');

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }

      // Android-specific: Try to use WhatsApp directly via Intent
      if (Platform.isAndroid) {
        try {
          // Use platform channel to send WhatsApp Intent with file
          const platform = MethodChannel('com.invoiceflow.app/whatsapp');

          await platform.invokeMethod('sendWhatsAppMessage', {
            'phoneNumber': phoneNumber,
            'message': message,
            'filePath': pdfPath,
          });

          if (mounted) {
            FeedbackAnimations.showSuccess(context, message: 'Opening WhatsApp...');
            HapticFeedbackUtil.success();
          }
        } catch (e) {
          print('Platform channel failed, using share sheet: $e');

          // Fallback to share sheet
          final result = await Share.shareXFiles(
            [XFile(pdfPath)],
            text: message,
          );

          if (mounted) {
            FeedbackAnimations.showSuccess(context, message: 'Please select WhatsApp');
            HapticFeedbackUtil.success();
          }
        }
      } else {
        // For iOS and other platforms, use share sheet
        final result = await Share.shareXFiles(
          [XFile(pdfPath)],
          text: message,
        );

        if (mounted) {
          FeedbackAnimations.showSuccess(context, message: 'Please select WhatsApp');
          HapticFeedbackUtil.success();
        }
      }
    } catch (e) {
      print('Error sending WhatsApp reminder with summary PDF: $e');

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        FeedbackAnimations.showError(
          context,
          message: 'Failed to send reminder: ${e.toString()}',
        );
        HapticFeedbackUtil.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppScaling.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: widget.totalDue > 0 && !_isGenerating ? () => _sendWhatsAppReminder(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _isGenerating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.message, size: AppScaling.iconSize),
        label: Text(
          _isGenerating ? 'Generating PDF...' : 'Remind on WhatsApp',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppScaling.button,
          ),
        ),
      ),
    );
  }
}