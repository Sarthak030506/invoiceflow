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
  
  /// Rounds a monetary value to 2 decimal places to prevent floating-point drift.
  static double roundMoney(double v) => (v * 100).roundToDouble() / 100.0;

  String generateWhatsAppReminderLink(InvoiceModel invoice, String shopName, String shopContact) {
    // Use adjustedTotal (not total) so refund adjustments are reflected
    final double pendingAmount = roundMoney(invoice.adjustedTotal - invoice.amountPaid);
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
- Total amount: ₹${invoice.adjustedTotal.toStringAsFixed(2)}
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

  // Manually adjust outstanding balance for a customer
  // This updates the invoice payments to reflect partial payments
  Future<void> adjustOutstandingBalance(String customerId, double newOutstandingAmount) async {
    if (newOutstandingAmount < 0) {
      throw ArgumentError('Outstanding balance cannot be negative');
    }

    await _fs.adjustCustomerOutstandingBalance(customerId, newOutstandingAmount);
  }

  /// Fast path: apply a known invoice delta to customer stats without re-reading all invoices.
  /// Reads only the customer doc (1 read) instead of getInvoicesByCustomerId (N reads).
  Future<void> updateCustomerStatsWithDelta({
    required String customerId,
    InvoiceModel? addedInvoice,
    InvoiceModel? removedInvoice,
    InvoiceModel? oldVersion,
    InvoiceModel? newVersion,
  }) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    double spentDelta = 0.0;
    double paidDelta = 0.0;
    int countDelta = 0;
    DateTime? newLastPurchase;

    if (addedInvoice != null &&
        addedInvoice.invoiceType.toLowerCase() == 'sales' &&
        addedInvoice.status != 'cancelled') {
      spentDelta += addedInvoice.adjustedTotal;
      paidDelta += addedInvoice.amountPaid;
      countDelta += 1;
      newLastPurchase = addedInvoice.date;
    }

    if (removedInvoice != null &&
        removedInvoice.invoiceType.toLowerCase() == 'sales' &&
        removedInvoice.status != 'cancelled') {
      spentDelta -= removedInvoice.adjustedTotal;
      paidDelta -= removedInvoice.amountPaid;
      countDelta -= 1;
    }

    if (oldVersion != null && newVersion != null) {
      final oldActive = oldVersion.invoiceType.toLowerCase() == 'sales' && oldVersion.status != 'cancelled';
      final newActive = newVersion.invoiceType.toLowerCase() == 'sales' && newVersion.status != 'cancelled';
      if (oldActive) {
        spentDelta -= oldVersion.adjustedTotal;
        paidDelta -= oldVersion.amountPaid;
        countDelta -= 1;
      }
      if (newActive) {
        spentDelta += newVersion.adjustedTotal;
        paidDelta += newVersion.amountPaid;
        countDelta += 1;
        newLastPurchase = newVersion.date;
      }
    }

    final updated = customer.copyWith(
      totalSpent: (customer.totalSpent + spentDelta).clamp(0.0, double.infinity),
      totalPaid: (customer.totalPaid + paidDelta).clamp(0.0, double.infinity),
      invoiceCount: (customer.invoiceCount + countDelta).clamp(0, 999999999),
      lastPurchaseDate: newLastPurchase != null &&
              (customer.lastPurchaseDate == null ||
                  newLastPurchase.isAfter(customer.lastPurchaseDate!))
          ? newLastPurchase
          : customer.lastPurchaseDate,
      updatedAt: DateTime.now(),
    );
    await _fs.upsertCustomer(updated);
  }

  /// Update denormalized customer stats (called when invoices change)
  /// This provides instant analytics without querying all invoices
  Future<void> updateCustomerStats(String customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    // Get all invoices for this customer
    final invoices = await _fs.getInvoicesByCustomerId(customerId);

    double totalSpent = 0.0;
    double totalPaid = 0.0;
    DateTime? lastPurchaseDate;

    for (final invoice in invoices) {
      if (invoice.invoiceType.toLowerCase() == 'sales' && invoice.status != 'cancelled') {
        totalSpent += invoice.adjustedTotal;
        totalPaid += invoice.amountPaid;

        if (lastPurchaseDate == null || invoice.date.isAfter(lastPurchaseDate)) {
          lastPurchaseDate = invoice.date;
        }
      }
    }

    // Update customer with denormalized stats
    final updatedCustomer = customer.copyWith(
      totalSpent: totalSpent,
      totalPaid: totalPaid,
      invoiceCount: invoices.where((inv) => inv.invoiceType.toLowerCase() == 'sales' && inv.status != 'cancelled').length,
      lastPurchaseDate: lastPurchaseDate,
      updatedAt: DateTime.now(),
    );

    await _fs.upsertCustomer(updatedCustomer);
  }
}