import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_scaling.dart';
import '../../../models/customer_model.dart';

class WhatsAppDueReminderButton extends StatelessWidget {
  final CustomerModel customer;
  final double totalDue;

  const WhatsAppDueReminderButton({
    Key? key,
    required this.customer,
    required this.totalDue,
  }) : super(key: key);

  Future<void> _sendWhatsAppReminder() async {
    try {
      if (customer.phoneNumber.isEmpty) {
        return;
      }

      final message = '''Hello ${customer.name},

This is a friendly reminder regarding your outstanding balance.

Total Due: ₹${totalDue.toStringAsFixed(2)}

Please arrange for the payment at your earliest convenience.

Thank you for your business!

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';

      String phoneNumber = customer.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      
      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }
      
      if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
        phoneNumber = '91$phoneNumber';
      }

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      final whatsappUri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppScaling.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: totalDue > 0 ? _sendWhatsAppReminder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.message, size: AppScaling.iconSize),
        label: Text(
          'Remind on WhatsApp',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppScaling.button,
          ),
        ),
      ),
    );
  }
}