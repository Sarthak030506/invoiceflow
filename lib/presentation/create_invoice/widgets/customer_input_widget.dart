import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/customer_model.dart';
import '../../../services/customer_service.dart';

class CustomerInputWidget extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final Function(String name, String phone, String? customerId) onCustomerSelected;
  
  const CustomerInputWidget({
    Key? key,
    this.initialName,
    this.initialPhone,
    required this.onCustomerSelected,
  }) : super(key: key);

  @override
  State<CustomerInputWidget> createState() => _CustomerInputWidgetState();
}

class _CustomerInputWidgetState extends State<CustomerInputWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  
  List<CustomerModel> _existingCustomers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isLoading = false;
  bool _isPhoneValid = true;
  String? _selectedCustomerId;
  
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    _loadCustomers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _existingCustomers = customers;
        _filteredCustomers = List.from(customers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterCustomers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = List.from(_existingCustomers);
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCustomers = _existingCustomers.where((customer) {
        return customer.name.toLowerCase().contains(lowerQuery) ||
               customer.phoneNumber.contains(query);
      }).toList();
    });
  }
  
  bool _validatePhone(String phone) {
    // Basic validation for Indian phone numbers
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }
  
  void _selectCustomer(CustomerModel customer) {
    setState(() {
      _nameController.text = customer.name;
      _phoneController.text = customer.phoneNumber;
      _selectedCustomerId = customer.id;
      _isPhoneValid = true;
    });
    
    widget.onCustomerSelected(
      customer.name,
      customer.phoneNumber,
      customer.id,
    );
  }
  
  void _onNameChanged(String value) {
    _filterCustomers(value);
    widget.onCustomerSelected(
      value,
      _phoneController.text,
      _selectedCustomerId,
    );
  }
  
  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneValid = value.isEmpty || _validatePhone(value);
    });
    
    _filterCustomers(value);
    
    if (_isPhoneValid && value.isNotEmpty) {
      widget.onCustomerSelected(
        _nameController.text,
        value,
        _selectedCustomerId,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        
        // Customer Name Field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Customer Name (Optional)',
            hintText: 'Enter customer name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _onNameChanged,
        ),
        SizedBox(height: 2.h),
        
        // Customer Phone Field
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorText: _isPhoneValid ? null : 'Please enter a valid 10-digit mobile number',
            helperText: 'Required for WhatsApp reminders',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: _onPhoneChanged,
        ),
        SizedBox(height: 2.h),
        
        // Existing Customers List
        if (_filteredCustomers.isNotEmpty) ...[
          Text(
            'Existing Customers',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 15.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(customer.phoneNumber),
                        onTap: () => _selectCustomer(customer),
                        selected: _selectedCustomerId == customer.id,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}