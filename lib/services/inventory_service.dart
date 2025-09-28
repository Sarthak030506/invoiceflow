import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/reorder_item_model.dart';
import 'inventory_firestore_service.dart';
import './inventory_notification_service.dart';
import './stock_map_service.dart';
import '../utils/app_logger.dart';
import 'dart:async';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final InventoryFirestoreService _db = InventoryFirestoreService.instance;
  final StreamController<void> _inventoryUpdatesController = StreamController<void>.broadcast();
  
  Stream<void> get inventoryUpdates => _inventoryUpdatesController.stream;

  Future<List<InventoryItem>> getAllItems() async {
    return await _db.getAllItems();
  }

  Future<List<Map<String, dynamic>>> getSellableItems() async {
    return await _db.getSellableItems();
  }
  
  Future<List<Map<String, dynamic>>> getItemsForPicker() async {
    return await getSellableItems();
  }
  
  /// Creates a new inventory item from invoice data (for purchase invoices with new items)
  Future<InventoryItem> createItemFromInvoice(Map<String, dynamic> itemData) async {
    final newItem = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: itemData['name'] as String,
      sku: itemData['sku'] as String? ?? '',
      category: itemData['category'] as String? ?? 'General',
      unit: itemData['unit'] as String? ?? 'pcs',
      avgCost: (itemData['rate'] as num?)?.toDouble() ?? 0.0,
      openingStock: 0.0,
      currentStock: 0.0,
      reorderPoint: 10.0,
      barcode: itemData['barcode'] as String? ?? '',
      lastUpdated: DateTime.now(),
    );
    
    await addItem(newItem);
    _inventoryUpdatesController.add(null); // Notify UI of new item
    return newItem;
  }

  Future<InventoryItem?> getItemById(String itemId) async {
    return await _db.getItemById(itemId);
  }

  Future<InventoryItem?> getItemBySku(String sku) async {
    return await _db.getItemBySku(sku);
  }

  Future<InventoryItem?> getItemByBarcode(String barcode) async {
    final items = await getAllItems();
    try {
      return items.firstWhere((item) => item.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    return await _db.getLowStockItems();
  }

  Future<void> receiveStock(String itemId, double qty, double unitCost, String sourceRef) async {
    if (qty <= 0) throw Exception('Quantity must be positive');
    
    final movement = StockMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: itemId,
      type: sourceRef.contains('return') ? StockMovementType.RETURN_IN : StockMovementType.IN,
      quantity: qty,
      unitCost: unitCost,
      sourceRefType: sourceRef.split(':')[0],
      sourceRefId: sourceRef.split(':')[1],
      createdAt: DateTime.now(),
    );
    
    await addMovement(movement);
    await _updateItemCurrentStock(itemId);
    await refreshMetricsAndNotify();
    _inventoryUpdatesController.add(null);
    StockMapService().notifyInventoryUpdated();
  }

  Future<bool> issueStock(String itemId, double qty, String sourceRef) async {
    if (qty <= 0) throw Exception('Quantity must be positive');
    
    final currentStock = await computeCurrentStock(itemId);
    if (currentStock < qty) {
      final item = await getItemById(itemId);
      throw Exception('Insufficient stock for ${item?.name ?? itemId}. Available: $currentStock, Required: $qty');
    }
    
    final movement = StockMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: itemId,
      type: sourceRef.contains('return') ? StockMovementType.RETURN_OUT : StockMovementType.OUT,
      quantity: qty,
      unitCost: 0.0,
      sourceRefType: sourceRef.split(':')[0],
      sourceRefId: sourceRef.split(':')[1],
      createdAt: DateTime.now(),
    );
    
    await addMovement(movement);
    await _updateItemCurrentStock(itemId);
    await refreshMetricsAndNotify();
    _inventoryUpdatesController.add(null);
    StockMapService().notifyInventoryUpdated();
    return true;
  }

  Future<void> adjustStock(String itemId, double deltaQty, String reason, {bool allowNegative = false}) async {
    if (deltaQty == 0) throw Exception('Adjustment quantity cannot be zero');
    
    final currentStock = await computeCurrentStock(itemId);
    final newStock = currentStock + deltaQty;
    
    if (!allowNegative && newStock < 0) {
      final item = await getItemById(itemId);
      throw Exception('Adjustment would result in negative stock for ${item?.name ?? itemId}: $newStock');
    }
    
    final movement = StockMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: itemId,
      type: StockMovementType.ADJUSTMENT,
      quantity: deltaQty, // Store the delta, not the new total
      unitCost: 0.0,
      sourceRefType: 'adjustment',
      sourceRefId: reason,
      createdAt: DateTime.now(),
    );
    
    await addMovement(movement);
    await _updateItemCurrentStock(itemId);
    await refreshMetricsAndNotify();
    _inventoryUpdatesController.add(null);
    StockMapService().notifyInventoryUpdated();
  }

  Future<double> computeCurrentStock(String itemId) async {
    return await _db.computeCurrentStock(itemId);
  }

  Future<List<ReorderItem>> generateReorderList() async {
    final lowStockItems = await getLowStockItems();
    return lowStockItems.map((item) {
      final suggestedQty = _calculateSuggestedQuantity(item);
      return ReorderItem(
        itemId: item.id,
        name: item.name,
        sku: item.sku,
        currentStock: item.currentStock,
        reorderPoint: item.reorderPoint,
        suggestedQty: suggestedQty,
        avgCost: item.avgCost,
        unit: item.unit,
      );
    }).toList();
  }

  double _calculateSuggestedQuantity(InventoryItem item) {
    final deficit = item.reorderPoint - item.currentStock;
    final bufferStock = item.reorderPoint * 0.5;
    return (deficit + bufferStock).clamp(1.0, item.reorderPoint * 2);
  }

  Future<int> getLowStockCount() async {
    final lowStockItems = await getLowStockItems();
    return lowStockItems.length;
  }

  Future<int> getCriticalStockCount() async {
    final items = await getAllItems();
    return items.where((item) => item.currentStock <= 0).length;
  }

  Future<double> getInventoryValueOverTime() async {
    final items = await getAllItems();
    return items.fold<double>(0, (sum, item) => sum + (item.currentStock * item.avgCost));
  }

  Future<List<Map<String, dynamic>>> getFastMovingItems({int limit = 10}) async {
    final items = await getAllItems();
    // Simulate fast-moving calculation based on current stock vs opening stock
    final fastMoving = items.map((item) {
      final movement = item.openingStock - item.currentStock;
      return {
        'item': item,
        'movement': movement,
        'turnoverRate': item.openingStock > 0 ? movement / item.openingStock : 0.0,
      };
    }).where((data) => (data['movement'] as double) > 0).toList();
    
    fastMoving.sort((a, b) => (b['turnoverRate'] as double).compareTo(a['turnoverRate'] as double));
    return fastMoving.take(limit).toList();
  }

  Future<List<InventoryItem>> getSlowMovingItems({int daysSinceLastMovement = 30}) async {
    final items = await getAllItems();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLastMovement));
    
    return items.where((item) => item.lastUpdated.isBefore(cutoffDate)).toList();
  }

  Future<Map<String, dynamic>> getInventoryAnalytics() async {
    final items = await getAllItems();
    final lowStockItems = await getLowStockItems();
    final fastMoving = await getFastMovingItems(limit: 5);
    final slowMoving = await getSlowMovingItems();
    final totalValue = await getInventoryValueOverTime();
    
    return {
      'totalItems': items.length,
      'totalValue': totalValue,
      'lowStockCount': lowStockItems.length,
      'fastMovingItems': fastMoving,
      'slowMovingItems': slowMoving,
      'averageStockValue': items.isNotEmpty ? totalValue / items.length : 0.0,
    };
  }

  Future<void> processInvoiceStock(String invoiceId, String invoiceType, List<Map<String, dynamic>> items) async {
    for (final itemData in items) {
      String itemId = itemData['itemId'] as String;
      final qty = itemData['quantity'] as double;
      final unitCost = itemData['unitCost'] as double? ?? 0.0;
      
      // For purchase invoices, check if item exists, create if not
      if (invoiceType == 'purchase') {
        final existingItem = await getItemById(itemId);
        if (existingItem == null) {
          // Create new item from invoice data
          final newItem = await createItemFromInvoice({
            'name': itemData['name'] ?? 'New Item',
            'rate': unitCost,
            'sku': itemData['sku'],
            'category': itemData['category'],
            'unit': itemData['unit'],
            'barcode': itemData['barcode'],
          });
          itemId = newItem.id;
        }
        await receiveStock(itemId, qty, unitCost, 'invoice:$invoiceId');
      } else if (invoiceType == 'sales') {
        await issueStock(itemId, qty, 'invoice:$invoiceId');
      }
    }
  }

  Future<void> processReturnStock(String returnId, String returnType, List<Map<String, dynamic>> items) async {
    for (final itemData in items) {
      final itemId = itemData['itemId'] as String;
      final qty = itemData['quantity'] as double;
      final unitCost = itemData['unitCost'] as double? ?? 0.0;
      
      if (returnType == 'sales_return') {
        await receiveStock(itemId, qty, unitCost, 'return:$returnId');
      } else if (returnType == 'purchase_return') {
        await issueStock(itemId, qty, 'return:$returnId');
      }
    }
  }



  Future<void> addItem(InventoryItem item) async {
    await _db.insertItem(item);
  }

  Future<void> updateItem(InventoryItem item) async {
    await _db.updateItem(item);
  }

  Future<void> deleteItem(String itemId) async {
    await _db.deleteItem(itemId);
    await refreshMetricsAndNotify();
  }

  Future<void> addMovement(StockMovement movement) async {
    await _db.insertMovement(movement);
  }

  Future<void> _updateItemCurrentStock(String itemId) async {
    final item = await getItemById(itemId);
    if (item != null) {
      final actualStock = await computeCurrentStock(itemId);
      if (actualStock != item.currentStock) {
        final updatedItem = item.copyWith(currentStock: actualStock, lastUpdated: DateTime.now());
        await updateItem(updatedItem);
        InventoryNotificationService().notifyItemUpdated(updatedItem);
      }
    }
  }

  Future<void> reverseInvoiceMovements(String sourceType, String sourceId) async {
    await _db.reverseMovementsAtomically(sourceType, sourceId);
    await refreshMetricsAndNotify();
  }

  Future<List<StockMovement>> getMovementsBySource(String sourceType, String sourceId) async {
    return await _db.getMovementsBySource(sourceType, sourceId);
  }

  Future<List<StockMovement>> getMovementsByItem(String itemId) async {
    return await _db.getMovementsByItem(itemId);
  }

  /// Refreshes inventory metrics and triggers low-stock notifications
  Future<void> refreshMetricsAndNotify() async {
    final allItems = await getAllItems();
    final previousLowStock = await getLowStockItems();
    
    // Recompute all items to ensure current stock is accurate
    for (final item in allItems) {
      final actualStock = await _db.computeCurrentStock(item.id);
      if (actualStock != item.currentStock) {
        final updatedItem = item.copyWith(currentStock: actualStock, lastUpdated: DateTime.now());
        await updateItem(updatedItem);
        InventoryNotificationService().notifyItemUpdated(updatedItem);
      }
    }
    
    // Get updated low stock items
    final currentLowStock = await getLowStockItems();
    
    // Check for new low stock items and fire notifications
    final newLowStockItems = currentLowStock.where((item) => 
      !previousLowStock.any((prev) => prev.id == item.id)
    ).toList();
    
    if (newLowStockItems.isNotEmpty) {
      await _fireNotifications(newLowStockItems);
    }
    
    // Notify UI of low stock changes
    InventoryNotificationService().notifyLowStock(currentLowStock);
    
    // Calculate and notify metrics
    final metrics = await getInventoryAnalytics();
    InventoryNotificationService().notifyMetricsUpdated(metrics);
  }

  /// Fires notifications for low stock items
  Future<void> _fireNotifications(List<InventoryItem> lowStockItems) async {
    for (final item in lowStockItems) {
      AppLogger.warning('LOW STOCK ALERT: ${item.name} - Current: ${item.currentStock}, Reorder: ${item.reorderPoint}', 'Inventory');
    }
  }

  /// Validates if invoice can be cancelled without causing negative stock
  Future<Map<String, dynamic>> validateInvoiceCancellation(String sourceType, String sourceId) async {
    final movements = await getMovementsBySource(sourceType, sourceId);
    final List<Map<String, dynamic>> issues = [];
    final List<String> dependentDocs = [];
    
    for (final movement in movements) {
      if (movement.type == StockMovementType.IN) {
        final currentStock = await computeCurrentStock(movement.itemId);
        final wouldBeStock = currentStock - movement.quantity;
        
        if (wouldBeStock < 0) {
          final item = await getItemById(movement.itemId);
          issues.add({
            'itemId': movement.itemId,
            'itemName': item?.name ?? 'Unknown',
            'currentStock': currentStock,
            'movementQty': movement.quantity,
            'resultingStock': wouldBeStock,
          });
        }
        
        // Check for dependent documents (subsequent OUT movements)
        final subsequentMovements = await _db.getMovementsAfterDate(movement.itemId, movement.createdAt);
        final outMovements = subsequentMovements.where((m) => 
          m.type == StockMovementType.OUT && 
          m.sourceRefType != sourceType && 
          m.sourceRefId != sourceId
        ).toList();
        
        if (outMovements.isNotEmpty) {
          for (final outMovement in outMovements) {
            dependentDocs.add('${outMovement.sourceRefType}:${outMovement.sourceRefId}');
          }
        }
      }
    }
    
    return {
      'canCancel': issues.isEmpty && dependentDocs.isEmpty,
      'negativeStockIssues': issues,
      'dependentDocuments': dependentDocs.toSet().toList(),
    };
  }

  /// Cancels invoice with admin override for negative stock
  Future<void> cancelInvoiceWithOverride(String sourceType, String sourceId, String adminReason) async {
    final movements = await getMovementsBySource(sourceType, sourceId);
    
    // First reverse the movements atomically
    await _db.reverseMovementsAtomically(sourceType, sourceId);
    
    // Then create adjustment movements for items that went negative
    for (final movement in movements) {
      if (movement.type == StockMovementType.IN) {
        final currentStock = await computeCurrentStock(movement.itemId);
        
        if (currentStock < 0) {
          final adjustmentMovement = StockMovement(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            itemId: movement.itemId,
            type: StockMovementType.ADJUSTMENT,
            quantity: -currentStock, // Adjust to bring stock to 0
            unitCost: 0.0,
            sourceRefType: 'adjustment',
            sourceRefId: 'Invoice reversal with negative stock: $adminReason',
            createdAt: DateTime.now(),
          );
          await addMovement(adjustmentMovement);
        }
      }
    }
  }

  /// Adds an item directly to inventory without creating a purchase invoice
  Future<void> addItemDirectlyToInventory(dynamic catalogItem, double quantity) async {
    if (quantity <= 0) throw Exception('Quantity must be positive');
    
    // Check if item already exists in inventory
    String itemId;
    final existingItem = await _db.getItemByName(catalogItem.name);
    
    if (existingItem != null) {
      itemId = existingItem.id;
    } else {
      // Create new inventory item from catalog item
      final newItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: catalogItem.name,
        sku: 'SKU-${catalogItem.id}',
        category: 'General',
        unit: 'pcs',
        avgCost: catalogItem.rate,
        openingStock: 0.0,
        currentStock: 0.0,
        reorderPoint: 10.0,
        barcode: '',
        lastUpdated: DateTime.now(),
      );
      
      await addItem(newItem);
      itemId = newItem.id;
    }
    
    // Add stock movement for direct addition
    final movement = StockMovement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: itemId,
      type: StockMovementType.IN,
      quantity: quantity,
      unitCost: catalogItem.rate,
      sourceRefType: 'direct_add',
      sourceRefId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    
    await addMovement(movement);
    await _updateItemCurrentStock(itemId);
    await refreshMetricsAndNotify();
    _inventoryUpdatesController.add(null);
    StockMapService().notifyInventoryUpdated();
  }
}