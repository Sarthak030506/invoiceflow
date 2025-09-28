import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// Ensure url_launcher is version 6.2.4 or higher

import '../../../models/invoice_model.dart';
import '../../../utils/app_logger.dart';

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
  bool _isLoading = false;
  
  Future<void> _sendWhatsAppReminder() async {
    try {
      setState(() => _isLoading = true);
      
      if (widget.invoice.customerPhone == null || widget.invoice.customerPhone!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
        return;
      }
      
      // Format phone number - just get digits
      String phoneNumber = widget.invoice.customerPhone!.replaceAll(RegExp(r'\D'), '');
      
      // Ensure it has country code (India)
      if (phoneNumber.length == 10) {
        phoneNumber = '91$phoneNumber';
      } else if (phoneNumber.startsWith('0')) {
        // Remove leading zero and add country code
        phoneNumber = '91${phoneNumber.substring(1)}';
      }
      
      // Debug log phone number
      AppLogger.debug('Formatted phone number: $phoneNumber', 'WhatsApp');
      AppLogger.debug('Original phone number: ${widget.invoice.customerPhone}', 'WhatsApp');
      
      // Create a simple message
      final bool isPaid = widget.invoice.remainingAmount <= 0;
      String message;
      
      if (isPaid) {
        message = 'Hello ${widget.invoice.clientName}, Thank you for your payment of ₹${widget.invoice.amountPaid} for invoice ${widget.invoice.invoiceNumber}. - ${widget.shopName}\n\n📱 Download InvoiceFlow app:\nhttps://play.google.com/store/apps/details?id=com.invoiceflow.app';
      } else {
        message = 'Hello ${widget.invoice.clientName}, This is a reminder for your pending payment of ₹${widget.invoice.remainingAmount} for invoice ${widget.invoice.invoiceNumber}. - ${widget.shopName}\n\n📱 Download InvoiceFlow app:\nhttps://play.google.com/store/apps/details?id=com.invoiceflow.app';
      }
      
      final String encodedMessage = Uri.encodeComponent(message);
      
      try {
        // Create the URLs
        final String whatsappSchemeUrl = "whatsapp://send?phone=$phoneNumber&text=$encodedMessage";
        final String waUrl = "https://wa.me/$phoneNumber?text=$encodedMessage";
        
        AppLogger.debug('Trying WhatsApp scheme URL: $whatsappSchemeUrl', 'WhatsApp');
        
        // APPROACH 1: Try whatsapp:// scheme first (most reliable on Android)
        final Uri whatsappUri = Uri.parse(whatsappSchemeUrl);
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
          return;
        }
        
        AppLogger.debug('WhatsApp scheme failed, trying wa.me URL', 'WhatsApp');
        
        // APPROACH 2: Try wa.me URL as fallback
        final Uri webUri = Uri.parse(waUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri);
          return;
        }
        
        AppLogger.debug('Both URL approaches failed, using share fallback', 'WhatsApp');
        
        // FALLBACK: Use system share dialog
        final String shareText = "$message\n\nOr open this link in your browser: $waUrl";
        await Share.share(shareText);
      } catch (e) {
        AppLogger.error('All WhatsApp launch attempts failed', 'WhatsApp', e);
        _showError('Could not open WhatsApp. Tap "Copy URL" to open manually.');
      }
    } catch (e) {
      AppLogger.error('Share error', 'WhatsApp', e);
      _showError('Error sharing message: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    // Format phone number for URL
    String phoneNumber = widget.invoice.customerPhone!.replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.length == 10) {
      phoneNumber = '91$phoneNumber';
    }
    final url = "https://wa.me/$phoneNumber";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WhatsApp not found or not supported. ' + message
        ),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Copy URL',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('URL copied: $url'),
                action: SnackBarAction(
                  label: 'Open Browser',
                  onPressed: () async {
                    final browserUrl = Uri.parse(url);
                    await launchUrl(browserUrl, mode: LaunchMode.inAppWebView);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Only show for sales invoices with a phone number
    if (widget.invoice.invoiceType != 'sales' || 
        widget.invoice.customerPhone == null || 
        widget.invoice.customerPhone!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final bool isPaid = widget.invoice.remainingAmount <= 0;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _sendWhatsAppReminder,
        icon: _isLoading 
            ? SizedBox(
                height: 20.sp,
                width: 20.sp,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.message,
                color: Colors.white,
                size: 20.sp,
              ),
        label: Text(
          _isLoading
              ? 'Opening WhatsApp...'
              : isPaid 
                  ? 'Send Payment Confirmation via WhatsApp'
                  : 'Send Payment Reminder via WhatsApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // WhatsApp green color
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}