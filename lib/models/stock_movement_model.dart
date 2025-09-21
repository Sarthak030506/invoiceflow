enum StockMovementType {
  IN,
  OUT,
  ADJUSTMENT,
  RETURN_IN,
  RETURN_OUT,
  REVERSAL_OUT,
}

class StockMovement {
  final String id;
  final String itemId;
  final StockMovementType type;
  final double quantity;
  final double unitCost;
  final String sourceRefType;
  final String sourceRefId;
  final DateTime createdAt;
  final String? reversalOfMovementId; // Links to original movement being reversed
  final bool reversalFlag; // True if this is a reversal movement
  final String? note; // Note or comment about this movement

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.unitCost,
    required this.sourceRefType,
    required this.sourceRefId,
    required this.createdAt,
    this.reversalOfMovementId,
    this.reversalFlag = false,
    this.note,
  });

  StockMovement copyWith({
    String? id,
    String? itemId,
    StockMovementType? type,
    double? quantity,
    double? unitCost,
    String? sourceRefType,
    String? sourceRefId,
    DateTime? createdAt,
    String? reversalOfMovementId,
    bool? reversalFlag,
    String? note,
  }) {
    return StockMovement(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      sourceRefType: sourceRefType ?? this.sourceRefType,
      sourceRefId: sourceRefId ?? this.sourceRefId,
      createdAt: createdAt ?? this.createdAt,
      reversalOfMovementId: reversalOfMovementId ?? this.reversalOfMovementId,
      reversalFlag: reversalFlag ?? this.reversalFlag,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type.name,
      'quantity': quantity,
      'unitCost': unitCost,
      'sourceRefType': sourceRefType,
      'sourceRefId': sourceRefId,
      'createdAt': createdAt.toIso8601String(),
      'reversalOfMovementId': reversalOfMovementId,
      'reversalFlag': reversalFlag ? 1 : 0,
      'note': note,
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      itemId: json['itemId'],
      type: StockMovementType.values.firstWhere((e) => e.name == json['type']),
      quantity: json['quantity']?.toDouble() ?? 0.0,
      unitCost: json['unitCost']?.toDouble() ?? 0.0,
      sourceRefType: json['sourceRefType'],
      sourceRefId: json['sourceRefId'],
      createdAt: DateTime.parse(json['createdAt']),
      reversalOfMovementId: json['reversalOfMovementId'],
      reversalFlag: (json['reversalFlag'] ?? 0) == 1,
      note: json['note'],
    );
  }
}