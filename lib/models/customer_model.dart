class CustomerModel {
  final String id;
  final String name;
  final String phoneNumber;
  final double pendingReturnAmount; // Amount to be returned to customer from sales returns
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.pendingReturnAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'pendingReturnAmount': pendingReturnAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    double? pendingReturnAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pendingReturnAmount: pendingReturnAmount ?? this.pendingReturnAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}