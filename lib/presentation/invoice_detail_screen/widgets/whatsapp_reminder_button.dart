import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/invoice_model.dart';
import '../../../services/customer_service.dart';
import '../../../services/pdf_service.dart';
import '../../../core/app_export.dart';

class WhatsAppReminderButton extends StatefulWidget {
  final InvoiceModel invoice;
  final String shopName;
  final String shopContact;

  const WhatsAppReminderButton({
    Key? key,
    required this.invoice,
    required this.shopName,
    required this.shopContact,
  }) : super(key: key);

  @override
  State<WhatsAppReminderButton> createState() => _WhatsAppReminderButtonState();
}

class _WhatsAppReminderButtonState extends State<WhatsAppReminderButton> {
  bool _isGenerating = false;

  Future<void> _sendWhatsAppReminder() async {
    if (widget.invoice.customerPhone == null || widget.invoice.customerPhone!.isEmpty) {
      if (mounted) {
        FeedbackAnimations.showError(context, message: 'No customer phone number available');
      }
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      print('Generating PDF for invoice: ${widget.invoice.invoiceNumber}');

      // Generate PDF
      final PdfService pdfService = PdfService.instance;
      final String pdfPath = await pdfService.getInvoicePdfPath(widget.invoice);

      print('PDF generated at: $pdfPath');

      // Generate WhatsApp message
      final CustomerService customerService = CustomerService.instance;
      final String whatsappUrl = customerService.generateWhatsAppReminderLink(
        widget.invoice,
        widget.shopName,
        widget.shopContact
      );

      // Extract message and phone number
      final uri = Uri.parse(whatsappUrl);
      final message = uri.queryParameters['text'] ?? '';
      String phoneNumber = widget.invoice.customerPhone ?? '';

      // Format phone number
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
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
      print('Error sending WhatsApp reminder: $e');

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
    final double pendingAmount = widget.invoice.total - widget.invoice.amountPaid;
    final bool isPaid = pendingAmount <= 0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: ElevatedButton.icon(
        onPressed: widget.invoice.customerPhone == null || widget.invoice.customerPhone!.isEmpty || _isGenerating
            ? null // Disable button if no phone number or generating
            : _sendWhatsAppReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.message, size: 24),
        label: Text(
          _isGenerating
              ? 'Generating PDF...'
              : widget.invoice.customerPhone == null || widget.invoice.customerPhone!.isEmpty
                  ? 'No Phone Number Available'
                  : isPaid
                      ? 'Send Payment Confirmation on WhatsApp'
                      : 'Send Payment Reminder on WhatsApp',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}