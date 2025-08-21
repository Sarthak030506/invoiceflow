import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../models/invoice_model.dart';
import '../../../services/customer_service.dart';

class WhatsAppReminderButton extends StatelessWidget {
  final InvoiceModel invoice;
  final String shopName;
  final String shopContact;

  const WhatsAppReminderButton({
    Key? key,
    required this.invoice,
    required this.shopName,
    required this.shopContact,
  }) : super(key: key);

  Future<void> _sendWhatsAppReminder() async {
    try {
      if (invoice.customerPhone == null || invoice.customerPhone!.isEmpty) {
        Fluttertoast.showToast(
          msg: "No customer phone number available",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      
      // Show phone number for debugging
      print('Customer phone: ${invoice.customerPhone}');
      
      // Use CustomerService to generate the WhatsApp link
      final CustomerService customerService = CustomerService();
      final String whatsappUrl = customerService.generateWhatsAppReminderLink(
        invoice, 
        shopName, 
        shopContact
      );
      
      // Print URL for debugging
      print('WhatsApp URL: $whatsappUrl');
      
      final Uri whatsappUri = Uri.parse(whatsappUrl);
      
      // Show loading indicator
      Fluttertoast.showToast(
        msg: "Opening WhatsApp...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      // Check if WhatsApp can be launched
      bool canLaunch = await canLaunchUrl(whatsappUri);
      print('Can launch URL: $canLaunch');
      
      if (canLaunch) {
        bool launched = await launchUrl(
          whatsappUri, 
          mode: LaunchMode.externalApplication
        );
        print('URL launched: $launched');
        
        if (!launched) {
          // Try alternative approach
          final alternativeUri = Uri.parse('whatsapp://send?phone=${invoice.customerPhone}&text=${Uri.encodeComponent("Hello from InvoiceFlow")}');
          await launchUrl(alternativeUri, mode: LaunchMode.externalApplication);
        }
      } else {
        // Try direct intent
        final fallbackUrl = 'https://api.whatsapp.com/send?phone=${invoice.customerPhone?.replaceAll(RegExp(r'[^0-9]'), '')}';
        final fallbackUri = Uri.parse(fallbackUrl);
        
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          // Try to open WhatsApp directly
          final whatsappUri = Uri.parse('whatsapp://');
          if (await canLaunchUrl(whatsappUri)) {
            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
            Fluttertoast.showToast(
              msg: "WhatsApp opened. Please search for ${invoice.customerPhone} manually.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            Fluttertoast.showToast(
              msg: "Could not launch WhatsApp. Make sure WhatsApp is installed.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      Fluttertoast.showToast(
        msg: "Error sending WhatsApp message: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pendingAmount = invoice.total - invoice.amountPaid;
    final bool isPaid = pendingAmount <= 0;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: ElevatedButton.icon(
        onPressed: invoice.customerPhone == null || invoice.customerPhone!.isEmpty
            ? null // Disable button if no phone number
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
        icon: Icon(Icons.message, size: 24),
        label: Text(
          invoice.customerPhone == null || invoice.customerPhone!.isEmpty
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