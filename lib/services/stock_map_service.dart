import 'dart:async';
import '../models/catalog_item.dart';
import 'inventory_service.dart';

class StockMapService {
  static final StockMapService _instance = StockMapService._internal();
  factory StockMapService() => _instance;
  StockMapService._internal();

  final InventoryService _inventoryService = InventoryService();
  final StreamController<void> _inventoryUpdatesController = StreamController<void>.broadcast();
  
  Stream<void> get inventoryUpdates => _inventoryUpdatesController.stream;

  Future<Map<int, int>> getCurrentStockMap() async {
    try {
      final items = await _inventoryService.getAllItems();
      final stockMap = <int, int>{};
      for (final inv in items) {
        // Map inventory item to catalog item by name
        for (final catalogItem in ItemCatalog.items) {
          if (catalogItem.name.toLowerCase() == inv.name.toLowerCase()) {
            stockMap[catalogItem.id] = inv.currentStock.toInt();
            break;
          }
        }
      }
      return stockMap;
    } catch (e) {
      print('Error loading stock map: $e');
      return {};
    }
  }

  void notifyInventoryUpdated() {
    _inventoryUpdatesController.add(null);
  }
}