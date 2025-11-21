import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/catalog_item.dart';

/// ItemsService manages the product catalog (items that can be sold)
/// This is separate from inventory which tracks stock levels
class ItemsService {
  static final ItemsService _instance = ItemsService._internal();
  factory ItemsService() => _instance;
  ItemsService._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be signed in for items operations');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) =>
      _fs.collection('users').doc(uid).collection('items_catalog');

  // Get all items in the catalog
  Future<List<ProductCatalogItem>> getAllItems() async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).get();
    return q.docs.map((d) => _itemFromFirestore(d.data()..['id'] = d.id)).toList();
  }

  // Get item by ID
  Future<ProductCatalogItem?> getItemById(String itemId) async {
    final uid = _requireUid();
    final d = await _itemsCol(uid).doc(itemId).get();
    if (!d.exists) return null;
    return _itemFromFirestore(d.data()!..['id'] = d.id);
  }

  // Get item by SKU
  Future<ProductCatalogItem?> getItemBySku(String sku) async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).where('sku', isEqualTo: sku).limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return _itemFromFirestore(d.data()..['id'] = d.id);
  }

  // Get items by category
  Future<List<ProductCatalogItem>> getItemsByCategory(String category) async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).where('category', isEqualTo: category).get();
    return q.docs.map((d) => _itemFromFirestore(d.data()..['id'] = d.id)).toList();
  }

  // Add a new item to the catalog
  Future<void> addItem(ProductCatalogItem item) async {
    final uid = _requireUid();
    final data = _itemToFirestore(item);
    await _itemsCol(uid).doc(item.id).set(data);
  }

  // Update an existing item
  Future<void> updateItem(ProductCatalogItem item) async {
    final uid = _requireUid();
    final data = _itemToFirestore(item);
    await _itemsCol(uid).doc(item.id).update(data);
  }

  // Delete an item from the catalog
  Future<void> deleteItem(String itemId) async {
    final uid = _requireUid();
    await _itemsCol(uid).doc(itemId).delete();
  }

  // Batch add multiple items (useful for demo data import)
  Future<void> addMultipleItems(List<ProductCatalogItem> items) async {
    final uid = _requireUid();
    final batch = _fs.batch();

    for (final item in items) {
      final data = _itemToFirestore(item);
      batch.set(_itemsCol(uid).doc(item.id), data);
    }

    await batch.commit();
  }

  // Batch add multiple items from maps (for template imports)
  Future<void> addMultipleItemsFromMaps(List<dynamic> itemMaps) async {
    final uid = _requireUid();
    final batch = _fs.batch();

    for (final itemMap in itemMaps) {
      final map = itemMap as Map<String, dynamic>;
      final id = map['id'] as String;
      final data = {
        'name': map['name'],
        'sku': map['sku'],
        'category': map['category'],
        'unit': map['unit'],
        'rate': map['rate'],
        'barcode': map['barcode'] ?? '',
        'description': map['description'] ?? '',
        'createdAt': Timestamp.fromDate(DateTime.parse(map['createdAt'])),
        'updatedAt': Timestamp.fromDate(DateTime.parse(map['updatedAt'])),
      };
      batch.set(_itemsCol(uid).doc(id), data);
    }

    await batch.commit();
  }

  // Search items by name
  Future<List<ProductCatalogItem>> searchItems(String query) async {
    final uid = _requireUid();
    // Note: Firestore doesn't have full-text search, so we'll get all items
    // and filter in-memory for now. For production, consider using Algolia.
    final items = await getAllItems();
    final lowerQuery = query.toLowerCase();
    return items.where((item) => 
      item.name.toLowerCase().contains(lowerQuery) ||
      item.sku.toLowerCase().contains(lowerQuery) ||
      item.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get unique categories
  Future<List<String>> getCategories() async {
    final items = await getAllItems();
    final categories = items.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get items count
  Future<int> getItemsCount() async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).count().get();
    return q.count ?? 0;
  }

  // Check if catalog is empty
  Future<bool> isCatalogEmpty() async {
    final count = await getItemsCount();
    return count == 0;
  }

  // Converters
  Map<String, dynamic> _itemToFirestore(ProductCatalogItem item) => {
    'name': item.name,
    'sku': item.sku,
    'category': item.category,
    'unit': item.unit,
    'rate': item.rate,
    'barcode': item.barcode,
    'description': item.description,
    'createdAt': Timestamp.fromDate(item.createdAt),
    'updatedAt': Timestamp.fromDate(item.updatedAt),
  };

  ProductCatalogItem _itemFromFirestore(Map<String, dynamic> data) => ProductCatalogItem(
    id: data['id'] as String,
    name: data['name'] as String? ?? '',
    sku: data['sku'] as String? ?? '',
    category: data['category'] as String? ?? 'General',
    unit: data['unit'] as String? ?? 'pcs',
    rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
    barcode: data['barcode'] as String?,
    description: data['description'] as String?,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

/// Product catalog item model (separate from inventory)
class ProductCatalogItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String unit;
  final double rate; // selling price
  final String? barcode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductCatalogItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.rate,
    this.barcode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductCatalogItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    String? unit,
    double? rate,
    String? barcode,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'unit': unit,
      'rate': rate,
      'barcode': barcode,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductCatalogItem.fromJson(Map<String, dynamic> json) {
    return ProductCatalogItem(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      category: json['category'],
      unit: json['unit'],
      rate: json['rate']?.toDouble() ?? 0.0,
      barcode: json['barcode'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
