import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import './database_service.dart';

class CustomerService {
  final DatabaseService _dbService = DatabaseService();
  
  Future<List<CustomerModel>> getAllCustomers() async {
    return await _dbService.getAllCustomers();
  }
  
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async {
    return await _dbService.getCustomerByPhone(phoneNumber);
  }
  
  Future<CustomerModel?> getCustomerById(String id) async {
    return await _dbService.getCustomerById(id);
  }
  
  Future<CustomerModel> addCustomer(String name, String phoneNumber) async {
    // Check if customer already exists
    final existingCustomer = await _dbService.getCustomerByPhone(phoneNumber);
    if (existingCustomer != null) {
      return existingCustomer;
    }
    
    // Create new customer
    final customer = CustomerModel(
      id: const Uuid().v4(),
      name: name,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _dbService.insertCustomer(customer);
    return customer;
  }
  
  Future<Map<String, double>> getCustomerOutstandingBalances() async {
    return await _dbService.getCustomerOutstandingBalances();
  }
  
  Future<List<InvoiceModel>> getCustomerInvoices(String customerId) async {
    return await _dbService.getInvoicesByCustomerId(customerId);
  }
  
  Future<void> deleteCustomer(String customerId) async {
    await _dbService.deleteCustomer(customerId);
  }
  
  String generateWhatsAppReminderLink(InvoiceModel invoice, String shopName, String shopContact) {
    // Check if invoice is paid or pending
    final double pendingAmount = invoice.total - invoice.amountPaid;
    final bool isPaid = pendingAmount <= 0;
    
    // Create appropriate message based on payment status
    String message;
    
    if (isPaid) {
      message = '''
Hello ${invoice.clientName},

Thank you for your payment of ₹${invoice.amountPaid.toStringAsFixed(2)} for invoice #${invoice.invoiceNumber}.
Your payment has been received in full.

Thank you for your business!

Regards,
$shopName
$shopContact
''';
    } else {
      message = '''
Hello ${invoice.clientName},

This is a friendly reminder from $shopName regarding your invoice #${invoice.invoiceNumber} dated ${invoice.getFormattedDate()}.

Invoice details:
- Total amount: ₹${invoice.total.toStringAsFixed(2)}
- Amount paid: ₹${invoice.amountPaid.toStringAsFixed(2)}
- Balance due: ₹${pendingAmount.toStringAsFixed(2)}

Please arrange for the payment at your earliest convenience.

Thank you for your business!

Regards,
$shopName
$shopContact
''';
    }

    // Format the phone number correctly
    String phoneNumber = invoice.customerPhone ?? '';
    
    // Remove any non-numeric characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If it starts with a '+', remove it for the WhatsApp API
    if (phoneNumber.startsWith('+')) {
      phoneNumber = phoneNumber.substring(1);
    }
    
    // If it doesn't have a country code and it's an Indian number (10 digits), add 91
    if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
      phoneNumber = '91$phoneNumber';
    }
    
    // Format the message for WhatsApp URL
    final encodedMessage = Uri.encodeComponent(message);
    
    // WhatsApp API URL
    return 'https://wa.me/$phoneNumber?text=$encodedMessage';
  }
}