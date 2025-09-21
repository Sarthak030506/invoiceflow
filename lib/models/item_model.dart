class ItemModel {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final int currentStock;
  final int minStock;
  final bool isDemo;

  const ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.currentStock,
    required this.minStock,
    this.isDemo = false,
  });
}