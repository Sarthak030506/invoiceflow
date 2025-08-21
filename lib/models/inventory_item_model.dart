class InventoryItem {
  final String id;
  final String sku;
  final String name;
  final String unit;
  final double openingStock;
  final double currentStock;
  final double reorderPoint;
  final double avgCost;
  final String category;
  final DateTime lastUpdated;
  final String? barcode;

  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.openingStock,
    required this.currentStock,
    required this.reorderPoint,
    required this.avgCost,
    required this.category,
    required this.lastUpdated,
    this.barcode,
  });

  double get inventoryValue => currentStock * avgCost;

  InventoryItem copyWith({
    String? id,
    String? sku,
    String? name,
    String? unit,
    double? openingStock,
    double? currentStock,
    double? reorderPoint,
    double? avgCost,
    String? category,
    DateTime? lastUpdated,
    String? barcode,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      avgCost: avgCost ?? this.avgCost,
      category: category ?? this.category,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      barcode: barcode ?? this.barcode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'unit': unit,
      'opening_stock': openingStock,
      'current_stock': currentStock,
      'reorder_point': reorderPoint,
      'avg_cost': avgCost,
      'category': category,
      'last_updated': lastUpdated.toIso8601String(),
      'barcode': barcode,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      sku: json['sku'],
      name: json['name'],
      unit: json['unit'],
      openingStock: json['opening_stock']?.toDouble() ?? 0.0,
      currentStock: json['current_stock']?.toDouble() ?? 0.0,
      reorderPoint: json['reorder_point']?.toDouble() ?? 0.0,
      avgCost: json['avg_cost']?.toDouble() ?? 0.0,
      category: json['category'],
      lastUpdated: DateTime.parse(json['last_updated']),
      barcode: json['barcode'],
    );
  }
}