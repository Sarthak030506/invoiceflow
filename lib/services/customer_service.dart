import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import './firestore_service.dart';

class CustomerService {
  // Singleton implementation
  static CustomerService? _instance;

  CustomerService._internal();

  static CustomerService get instance {
    _instance ??= CustomerService._internal();
    return _instance!;
  }

  final FirestoreService _fs = FirestoreService.instance;
  
  Future<List<CustomerModel>> getAllCustomers() async => _fs.getAllCustomers();
  
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async => _fs.getCustomerByPhone(phoneNumber);
  
  Future<CustomerModel?> getCustomerById(String id) async => _fs.getCustomerById(id);
  
  Future<CustomerModel> addCustomer(String name, String phoneNumber) async {
    // Check if customer already exists
    final existingCustomer = await _fs.getCustomerByPhone(phoneNumber);
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
    
    await _fs.upsertCustomer(customer);
    return customer;
  }
  
  Future<Map<String, double>> getCustomerOutstandingBalances() async => _fs.getCustomerOutstandingBalances();
  
  Future<List<InvoiceModel>> getCustomerInvoices(String customerId) async => _fs.getInvoicesByCustomerId(customerId);
  
  Future<void> deleteCustomer(String customerId) async => _fs.deleteCustomer(customerId);
  
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

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';
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

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';
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

  // Add pending return amount to customer
  Future<void> addPendingReturn(String customerId, double amount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final updatedCustomer = customer.copyWith(
        pendingReturnAmount: customer.pendingReturnAmount + amount,
        updatedAt: DateTime.now(),
      );
      await _fs.upsertCustomer(updatedCustomer);
    }
  }

  // Remove pending return amount from customer
  Future<void> removePendingReturn(String customerId, double amount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final newAmount = (customer.pendingReturnAmount - amount).clamp(0.0, double.infinity);
      final updatedCustomer = customer.copyWith(
        pendingReturnAmount: newAmount,
        updatedAt: DateTime.now(),
      );
      await _fs.upsertCustomer(updatedCustomer);
    }
  }

  // Clear all pending returns for a customer
  Future<void> clearPendingReturns(String customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final updatedCustomer = customer.copyWith(
        pendingReturnAmount: 0.0,
        updatedAt: DateTime.now(),
      );
      await _fs.upsertCustomer(updatedCustomer);
    }
  }
}