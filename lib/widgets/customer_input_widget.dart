import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import '../services/contact_picker_service.dart';

class CustomerInputWidget extends StatefulWidget {
  final TextEditingController controller;

  const CustomerInputWidget({Key? key, required this.controller}) : super(key: key);

  @override
  _CustomerInputWidgetState createState() => _CustomerInputWidgetState();
}

class _CustomerInputWidgetState extends State<CustomerInputWidget> {
  final _contactPicker = ContactPickerService();

  Future<void> _pickContact() async {
    print('CustomerInputWidget: Pick from contacts button pressed');

    try {
      final contact = await _contactPicker.pickContact();

      if (contact != null && mounted) {
        setState(() {
          widget.controller.text = contact.displayName ?? '';
          // Update other fields if needed
        });
        print('CustomerInputWidget: Selected contact: ${contact.displayName}');
      } else {
        print('CustomerInputWidget: No contact selected');
      }
    } catch (e) {
      print('CustomerInputWidget: Error picking contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error accessing contacts')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: 'Customer',
              suffixIcon: IconButton(
                icon: Icon(Icons.contacts),
                onPressed: _pickContact,
              ),
            ),
          ),
        ),
      ],
    );
  }
}