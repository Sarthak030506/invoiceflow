// Enum for payment status
enum PaymentStatus {
  paidInFull,
  balanceDue,
  refundDue,
}

// Enum for invoice status
enum InvoiceStatus {
  draft,
  posted,
  cancelled,
}

class InvoiceModel {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'customerPhone': customerPhone,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'revenue': revenue,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'invoiceType': invoiceType,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'followUpDate': followUpDate?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'modifiedFlag': modifiedFlag ? 1 : 0,
      'modifiedReason': modifiedReason,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  static InvoiceModel fromDb(Map<String, dynamic> map, List<Map<String, dynamic>> itemMaps) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      clientName: map['clientName'],
      customerPhone: map['customerPhone'],
      customerId: map['customerId'],
      date: DateTime.parse(map['date']),
      revenue: map['revenue'],
      status: map['status'],
      items: itemMaps.map((i) => InvoiceItem.fromDb(i)).toList(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      invoiceType: map['invoiceType'] ?? 'sales',
      amountPaid: map['amountPaid'] ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      followUpDate: map['followUpDate'] != null ? DateTime.parse(map['followUpDate']) : null,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
      cancelReason: map['cancelReason'],
      modifiedFlag: (map['modifiedFlag'] ?? 0) == 1,
      modifiedReason: map['modifiedReason'],
      modifiedAt: map['modifiedAt'] != null ? DateTime.parse(map['modifiedAt']) : null,
    );
  }

  // ... existing fields

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get taxRate => 0.0; // Default, update if your data includes tax info
  double get taxAmount => subtotal * taxRate / 100;
  double get total => subtotal + taxAmount;
  
  // Updated remaining amount calculation that handles overpayments
  double get remainingAmount => total - amountPaid;
  
  // Get the absolute remaining amount (always positive)
  double get absoluteRemainingAmount => (total - amountPaid).abs();
  
  // Check if customer has overpaid
  bool get isOverpaid => amountPaid > total;
  
  // Check if invoice is fully paid
  bool get isFullyPaid => (total - amountPaid).abs() < 0.01; // Using small epsilon for floating point comparison
  
  // Get payment status display text
  String get paymentStatusDisplay {
    final remaining = total - amountPaid;
    if (remaining.abs() < 0.01) {
      return "Paid in Full";
    } else if (remaining > 0) {
      return "Balance Due: ₹${remaining.toStringAsFixed(2)}";
    } else {
      return "Refund Due: ₹${(-remaining).toStringAsFixed(2)}";
    }
  }
  
  // Get payment status for UI styling
  PaymentStatus get paymentStatus {
    final remaining = total - amountPaid;
    if (remaining.abs() < 0.01) {
      return PaymentStatus.paidInFull;
    } else if (remaining > 0) {
      return PaymentStatus.balanceDue;
    } else {
      return PaymentStatus.refundDue;
    }
  }

  final String id;
  final String invoiceNumber;
  final String clientName;
  final String? customerPhone; // Added customer phone number
  final String? customerId; // Added customer ID reference
  final DateTime date;
  final double revenue;
  final String status;
  final List<InvoiceItem> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String invoiceType; // 'sales' or 'purchase'
  final double amountPaid; // Amount paid toward the invoice
  final String paymentMethod; // 'Cash', 'Online', or 'Cheque'
  final DateTime? followUpDate; // Date to follow up on this invoice
  final bool isDeleted; // Soft delete flag for drafts
  final DateTime? cancelledAt; // When invoice was cancelled
  final String? cancelReason; // Reason for cancellation
  final bool modifiedFlag; // Whether invoice has been modified by returns
  final String? modifiedReason; // Reason for modification
  final DateTime? modifiedAt; // When invoice was modified

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    this.customerPhone,
    this.customerId,
    required this.date,
    required this.revenue,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceType = 'sales', // Default to sales invoice
    this.amountPaid = 0.0, // Default to 0
    this.paymentMethod = 'Cash', // Default to Cash
    this.followUpDate, // Follow-up date for reminders
    this.isDeleted = false, // Default not deleted
    this.cancelledAt,
    this.cancelReason,
    this.modifiedFlag = false, // Default not modified
    this.modifiedReason,
    this.modifiedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? json['invoiceNumber'] ?? '',
      clientName: json['client_name'] ?? json['clientName'] ?? '',
      date: json['date'] is String
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : json['date'] ?? DateTime.now(),
      revenue: (json['revenue'] ?? json['total_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      items: (json['items'] as List?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      notes: json['notes'],
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : json['created_at'] ?? DateTime.now(),
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : json['updated_at'] ?? DateTime.now(),
      invoiceType: json['invoiceType'] ?? json['invoice_type'] ?? 'sales',
      amountPaid: (json['amountPaid'] ?? json['amount_paid'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? 'Cash',
    );
  }

  // Factory method to create from Google Sheets row data
  factory InvoiceModel.fromGoogleSheetsRow(Map<String, dynamic> row) {
    final items = <InvoiceItem>[];

    // Parse items from Google Sheets format
    if (row['items'] != null && row['items'].isNotEmpty) {
      try {
        final itemsStr = row['items'].toString();
        final itemParts = itemsStr.split(';');

        for (String itemPart in itemParts) {
          final parts = itemPart.split('|');
          if (parts.length >= 3) {
            items.add(InvoiceItem(
              name: parts[0].trim(),
              quantity: int.tryParse(parts[1].trim()) ?? 1,
              price: double.tryParse(parts[2].trim()) ?? 0.0,
            ));
          }
        }
      } catch (e) {
        // If parsing fails, create a single item with the total amount
        items.add(InvoiceItem(
          name: row['description'] ?? 'Service',
          quantity: 1,
          price: (row['revenue'] ?? 0.0).toDouble(),
        ));
      }
    }

    return InvoiceModel(
      id: row['id'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: row['invoice_number'] ?? row['invoiceNumber'] ?? '',
      clientName: row['client_name'] ?? row['clientName'] ?? '',
      date: _parseDate(row['date']),
      revenue: (row['revenue'] ?? row['total_amount'] ?? 0.0).toDouble(),
      status: _parseStatus(row['status']),
      items: items,
      notes: row['notes'],
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
      invoiceType: row['invoiceType'] ?? row['invoice_type'] ?? 'sales',
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is String) {
      // Try different date formats
      final formats = [
        'yyyy-MM-dd',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd HH:mm:ss',
        'MM/dd/yyyy HH:mm:ss',
      ];

      for (String format in formats) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          continue;
        }
      }
    }

    return DateTime.now();
  }

  static String _parseStatus(dynamic statusValue) {
    if (statusValue == null) return 'pending';

    final status = statusValue.toString().toLowerCase();
    const validStatuses = ['paid', 'pending', 'overdue', 'draft'];

    if (validStatuses.contains(status)) {
      return status;
    }

    return 'pending';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'revenue': revenue,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'invoiceType': invoiceType,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
    };
  }
  
  // Create a new invoice with updated values
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? clientName,
    String? customerPhone,
    String? customerId,
    DateTime? date,
    double? revenue,
    String? status,
    List<InvoiceItem>? items,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? invoiceType,
    double? amountPaid,
    String? paymentMethod,
    DateTime? followUpDate,
    DateTime? cancelledAt,
    String? cancelReason,
    bool? modifiedFlag,
    String? modifiedReason,
    DateTime? modifiedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientName: clientName ?? this.clientName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      revenue: revenue ?? this.revenue,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      invoiceType: invoiceType ?? this.invoiceType,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      followUpDate: followUpDate ?? this.followUpDate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      modifiedFlag: modifiedFlag ?? this.modifiedFlag,
      modifiedReason: modifiedReason ?? this.modifiedReason,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  // Helper method to get formatted date
  String getFormattedDate() {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper method to get formatted revenue
  String getFormattedRevenue() {
    return '₹${revenue.toStringAsFixed(2)}';
  }

  // Helper method to get status color
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'paid':
        return '#4CAF50';
      case 'pending':
        return '#FF9800';
      case 'overdue':
        return '#F44336';
      case 'draft':
        return '#9E9E9E';
      default:
        return '#FF9800';
    }
  }
}

class InvoiceItem {
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
  static InvoiceItem fromDb(Map<String, dynamic> map) {
    return InvoiceItem(
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
    );
  }

  final String name;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }

  double get totalPrice => quantity * price;
}
