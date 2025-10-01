class ReturnModel {
  final String id;
  final String returnNumber;
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String? customerId;
  final String? customerPhone;
  final DateTime invoiceDate;
  final DateTime returnDate;
  final String returnType; // 'sales' or 'purchase'
  final List<ReturnItem> items;
  final String returnReason;
  final String? notes;
  final double totalReturnValue;
  final double refundAmount;
  final bool isApplied; // Whether the return has been applied to customer's account
  final DateTime createdAt;
  final DateTime updatedAt;

  ReturnModel({
    required this.id,
    required this.returnNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerId,
    this.customerPhone,
    required this.invoiceDate,
    required this.returnDate,
    required this.returnType,
    required this.items,
    required this.returnReason,
    this.notes,
    required this.totalReturnValue,
    required this.refundAmount,
    this.isApplied = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnNumber': returnNumber,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerId': customerId,
      'customerPhone': customerPhone,
      'invoiceDate': invoiceDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'returnType': returnType,
      'items': items.map((item) => item.toMap()).toList(),
      'returnReason': returnReason,
      'notes': notes,
      'totalReturnValue': totalReturnValue,
      'refundAmount': refundAmount,
      'isApplied': isApplied ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ReturnModel fromMap(Map<String, dynamic> map) {
    return ReturnModel(
      id: map['id'],
      returnNumber: map['returnNumber'],
      invoiceId: map['invoiceId'],
      invoiceNumber: map['invoiceNumber'],
      customerName: map['customerName'],
      customerId: map['customerId'],
      customerPhone: map['customerPhone'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      returnDate: DateTime.parse(map['returnDate']),
      returnType: map['returnType'],
      items: (map['items'] as List)
          .map((item) => ReturnItem.fromMap(item))
          .toList(),
      returnReason: map['returnReason'],
      notes: map['notes'],
      totalReturnValue: map['totalReturnValue'],
      refundAmount: map['refundAmount'],
      isApplied: (map['isApplied'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'returnNumber': returnNumber,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerId': customerId,
      'customerPhone': customerPhone,
      'invoiceDate': invoiceDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'returnType': returnType,
      'items': items.map((item) => item.toJson()).toList(),
      'returnReason': returnReason,
      'notes': notes,
      'totalReturnValue': totalReturnValue,
      'refundAmount': refundAmount,
      'isApplied': isApplied,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ReturnModel fromJson(Map<String, dynamic> json) {
    return ReturnModel(
      id: json['id'],
      returnNumber: json['returnNumber'],
      invoiceId: json['invoiceId'],
      invoiceNumber: json['invoiceNumber'],
      customerName: json['customerName'],
      customerId: json['customerId'],
      customerPhone: json['customerPhone'],
      invoiceDate: DateTime.parse(json['invoiceDate']),
      returnDate: DateTime.parse(json['returnDate']),
      returnType: json['returnType'],
      items: (json['items'] as List)
          .map((item) => ReturnItem.fromJson(item))
          .toList(),
      returnReason: json['returnReason'],
      notes: json['notes'],
      totalReturnValue: json['totalReturnValue'].toDouble(),
      refundAmount: json['refundAmount'].toDouble(),
      isApplied: json['isApplied'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  ReturnModel copyWith({
    String? id,
    String? returnNumber,
    String? invoiceId,
    String? invoiceNumber,
    String? customerName,
    String? customerId,
    String? customerPhone,
    DateTime? invoiceDate,
    DateTime? returnDate,
    String? returnType,
    List<ReturnItem>? items,
    String? returnReason,
    String? notes,
    double? totalReturnValue,
    double? refundAmount,
    bool? isApplied,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReturnModel(
      id: id ?? this.id,
      returnNumber: returnNumber ?? this.returnNumber,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      customerPhone: customerPhone ?? this.customerPhone,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      returnDate: returnDate ?? this.returnDate,
      returnType: returnType ?? this.returnType,
      items: items ?? this.items,
      returnReason: returnReason ?? this.returnReason,
      notes: notes ?? this.notes,
      totalReturnValue: totalReturnValue ?? this.totalReturnValue,
      refundAmount: refundAmount ?? this.refundAmount,
      isApplied: isApplied ?? this.isApplied,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReturnItem {
  final String name;
  final int quantity;
  final double price;
  final double totalValue;

  ReturnItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'totalValue': totalValue,
    };
  }

  static ReturnItem fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      totalValue: map['totalValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'totalValue': totalValue,
    };
  }

  static ReturnItem fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      totalValue: json['totalValue'].toDouble(),
    );
  }
}
