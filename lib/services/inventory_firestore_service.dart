import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';

class InventoryFirestoreService {
  static final InventoryFirestoreService instance = InventoryFirestoreService._internal();
  InventoryFirestoreService._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be signed in for inventory operations');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) =>
      _fs.collection('users').doc(uid).collection('inventory_items');

  CollectionReference<Map<String, dynamic>> _movementsCol(String uid) =>
      _fs.collection('users').doc(uid).collection('stock_movements');

  // Inventory Items
  Future<List<InventoryItem>> getAllItems() async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).get();
    return q.docs.map((d) => _itemFromFirestore(d.data()..['id'] = d.id)).toList();
  }

  Future<List<Map<String, dynamic>>> getSellableItems() async {
    // Assuming all items are sellable in current model
    final items = await getAllItems();
    return items
        .map((i) => {
              'id': i.id,
              'name': i.name,
              'sku': i.sku,
              'rate': i.avgCost,
              'currentStock': i.currentStock,
              'category': i.category,
            })
        .toList();
  }

  Future<InventoryItem?> getItemById(String itemId) async {
    final uid = _requireUid();
    final d = await _itemsCol(uid).doc(itemId).get();
    if (!d.exists) return null;
    return _itemFromFirestore(d.data()!..['id'] = d.id);
  }

  Future<InventoryItem?> getItemBySku(String sku) async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).where('sku', isEqualTo: sku).limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return _itemFromFirestore(d.data()..['id'] = d.id);
  }

  Future<InventoryItem?> getItemByName(String name) async {
    final uid = _requireUid();
    final q = await _itemsCol(uid).where('name', isEqualTo: name).limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return _itemFromFirestore(d.data()..['id'] = d.id);
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final items = await getAllItems();
    return items.where((i) => i.currentStock <= i.reorderPoint).toList();
  }

  Future<void> insertItem(InventoryItem item) async {
    final uid = _requireUid();
    final data = _itemToFirestore(item);
    await _itemsCol(uid).doc(item.id).set(data);
  }

  Future<void> updateItem(InventoryItem item) async {
    final uid = _requireUid();
    final data = _itemToFirestore(item);
    await _itemsCol(uid).doc(item.id).update(data);
  }

  Future<void> deleteItem(String itemId) async {
    final uid = _requireUid();
    await _itemsCol(uid).doc(itemId).delete();
  }

  // Stock Movements
  Future<void> insertMovement(StockMovement movement) async {
    final uid = _requireUid();
    await _movementsCol(uid).doc(movement.id).set(_movementToFirestore(movement));
  }

  Future<List<StockMovement>> getMovementsBySource(String sourceType, String sourceId) async {
    final uid = _requireUid();
    final q = await _movementsCol(uid)
        .where('sourceRefType', isEqualTo: sourceType)
        .where('sourceRefId', isEqualTo: sourceId)
        .orderBy('createdAt')
        .get();
    return q.docs.map((d) => _movementFromFirestore(d.data())).toList();
  }

  Future<List<StockMovement>> getMovementsByItem(String itemId) async {
    final uid = _requireUid();
    final q = await _movementsCol(uid)
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt')
        .get();
    return q.docs.map((d) => _movementFromFirestore(d.data())).toList();
  }

  Future<List<StockMovement>> getMovementsAfterDate(String itemId, DateTime date) async {
    final uid = _requireUid();
    final q = await _movementsCol(uid)
        .where('itemId', isEqualTo: itemId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(date))
        .orderBy('createdAt')
        .get();
    return q.docs.map((d) => _movementFromFirestore(d.data())).toList();
  }

  Future<void> reverseMovementsAtomically(String sourceType, String sourceId) async {
    final uid = _requireUid();
    final batch = _fs.batch();
    final q = await _movementsCol(uid)
        .where('sourceRefType', isEqualTo: sourceType)
        .where('sourceRefId', isEqualTo: sourceId)
        .get();

    for (final d in q.docs) {
      final data = d.data();
      final movement = _movementFromFirestore(data);
      final reversal = movement.copyWith(
        id: '${movement.id}_rev',
        type: StockMovementType.REVERSAL_OUT,
        quantity: -movement.quantity,
        reversalOfMovementId: movement.id,
        reversalFlag: true,
        createdAt: DateTime.now(),
      );
      batch.set(_movementsCol(uid).doc(reversal.id), _movementToFirestore(reversal));
    }

    await batch.commit();
  }

  Future<double> computeCurrentStock(String itemId) async {
    final movements = await getMovementsByItem(itemId);
    double total = 0.0;
    for (final m in movements) {
      switch (m.type) {
        case StockMovementType.IN:
        case StockMovementType.RETURN_IN:
          total += m.quantity;
          break;
        case StockMovementType.OUT:
        case StockMovementType.RETURN_OUT:
        case StockMovementType.REVERSAL_OUT:
          total -= m.quantity;
          break;
        case StockMovementType.ADJUSTMENT:
          total += m.quantity;
          break;
      }
    }
    return total;
  }

  // Converters
  Map<String, dynamic> _itemToFirestore(InventoryItem item) => {
        'sku': item.sku,
        'name': item.name,
        'unit': item.unit,
        'opening_stock': item.openingStock,
        'current_stock': item.currentStock,
        'reorder_point': item.reorderPoint,
        'avg_cost': item.avgCost,
        'category': item.category,
        'last_updated': Timestamp.fromDate(item.lastUpdated),
        'barcode': item.barcode,
      };

  InventoryItem _itemFromFirestore(Map<String, dynamic> data) => InventoryItem(
        id: data['id'] as String,
        sku: data['sku'] as String? ?? '',
        name: data['name'] as String? ?? '',
        unit: data['unit'] as String? ?? 'pcs',
        openingStock: (data['opening_stock'] as num?)?.toDouble() ?? 0.0,
        currentStock: (data['current_stock'] as num?)?.toDouble() ?? 0.0,
        reorderPoint: (data['reorder_point'] as num?)?.toDouble() ?? 0.0,
        avgCost: (data['avg_cost'] as num?)?.toDouble() ?? 0.0,
        category: data['category'] as String? ?? 'General',
        lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        barcode: data['barcode'] as String?,
      );

  Map<String, dynamic> _movementToFirestore(StockMovement m) => {
        'id': m.id,
        'itemId': m.itemId,
        'type': m.type.name,
        'quantity': m.quantity,
        'unitCost': m.unitCost,
        'sourceRefType': m.sourceRefType,
        'sourceRefId': m.sourceRefId,
        'createdAt': Timestamp.fromDate(m.createdAt),
        'reversalOfMovementId': m.reversalOfMovementId,
        'reversalFlag': m.reversalFlag,
      };

  StockMovement _movementFromFirestore(Map<String, dynamic> data) => StockMovement(
        id: data['id'] as String,
        itemId: data['itemId'] as String,
        type: StockMovementType.values.firstWhere((e) => e.name == data['type']),
        quantity: (data['quantity'] as num).toDouble(),
        unitCost: (data['unitCost'] as num).toDouble(),
        sourceRefType: data['sourceRefType'] as String,
        sourceRefId: data['sourceRefId'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        reversalOfMovementId: data['reversalOfMovementId'] as String?,
        reversalFlag: (data['reversalFlag'] as bool?) ?? false,
      );
}
