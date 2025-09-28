import 'package:flutter_contacts/flutter_contacts.dart';
import '../utils/app_logger.dart';

class ContactModel {
  final String name;
  final String phoneNumber;

  ContactModel({required this.name, required this.phoneNumber});
}

class ContactPickerService {
  static Future<ContactModel?> pickContact() async {
    try {
      AppLogger.debug('Starting contact picker', 'ContactPicker');
      
      // Request permission first
      final hasPermission = await FlutterContacts.requestPermission();
      AppLogger.debug('Permission granted: $hasPermission', 'ContactPicker');
      
      if (!hasPermission) {
        AppLogger.warning('Permission denied', 'ContactPicker');
        return null;
      }
      
      // Pick contact
      AppLogger.debug('Opening external picker', 'ContactPicker');
      final contact = await FlutterContacts.openExternalPick();
      AppLogger.debug('Contact selected: ${contact?.displayName}', 'ContactPicker');
      
      if (contact != null && contact.phones.isNotEmpty) {
        final phone = _cleanPhoneNumber(contact.phones.first.number);
        AppLogger.debug('Cleaned phone: $phone', 'ContactPicker');
        if (phone.isNotEmpty) {
          return ContactModel(
            name: contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
            phoneNumber: phone,
          );
        }
      }
      
      AppLogger.debug('No valid contact selected', 'ContactPicker');
      return null;
    } catch (e) {
      AppLogger.error('Contact picker error', 'ContactPicker', e);
      return null;
    }
  }

  static String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If it starts with country code, remove it for Indian numbers
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    
    // Return only if it's a valid 10-digit number
    if (cleaned.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return cleaned;
    }
    
    return '';
  }
}