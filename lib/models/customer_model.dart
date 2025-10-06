class CustomerModel {
  final String id;
  final String name;
  final String phoneNumber;
  final double pendingReturnAmount; // Amount to be returned to customer from sales returns
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized stats for performance (updated on invoice changes)
  final double totalSpent; // Lifetime total spent
  final double totalPaid; // Lifetime total paid
  final int invoiceCount; // Total number of invoices
  final DateTime? lastPurchaseDate; // Last invoice date

  CustomerModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.pendingReturnAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.totalSpent = 0.0,
    this.totalPaid = 0.0,
    this.invoiceCount = 0,
    this.lastPurchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'pendingReturnAmount': pendingReturnAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalSpent': totalSpent,
      'totalPaid': totalPaid,
      'invoiceCount': invoiceCount,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
    };
  }

  static CustomerModel fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      pendingReturnAmount: (map['pendingReturnAmount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      invoiceCount: (map['invoiceCount'] ?? 0) as int,
      lastPurchaseDate: map['lastPurchaseDate'] != null ? DateTime.parse(map['lastPurchaseDate']) : null,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    double? pendingReturnAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalSpent,
    double? totalPaid,
    int? invoiceCount,
    DateTime? lastPurchaseDate,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pendingReturnAmount: pendingReturnAmount ?? this.pendingReturnAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalSpent: totalSpent ?? this.totalSpent,
      totalPaid: totalPaid ?? this.totalPaid,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
    );
  }

  // Computed property for outstanding amount
  double get outstandingAmount => totalSpent - totalPaid;
}