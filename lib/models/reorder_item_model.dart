class ReorderItem {
  final String itemId;
  final String name;
  final String sku;
  final double currentStock;
  final double reorderPoint;
  final double suggestedQty;
  final double avgCost;
  final String unit;

  const ReorderItem({
    required this.itemId,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.reorderPoint,
    required this.suggestedQty,
    required this.avgCost,
    required this.unit,
  });

  double get estimatedCost => suggestedQty * avgCost;
  bool get isCritical => currentStock <= 0;
  bool get isUrgent => currentStock <= (reorderPoint * 0.5);
}