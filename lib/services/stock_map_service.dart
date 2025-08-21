import 'dart:async';
import '../database/inventory_database.dart';
import '../models/catalog_item.dart';

class StockMapService {
  static final StockMapService _instance = StockMapService._internal();
  factory StockMapService() => _instance;
  StockMapService._internal();

  final InventoryDatabase _db = InventoryDatabase();
  final StreamController<void> _inventoryUpdatesController = StreamController<void>.broadcast();
  
  Stream<void> get inventoryUpdates => _inventoryUpdatesController.stream;

  Future<Map<int, int>> getCurrentStockMap() async {
    try {
      final db = await _db.database;
      final maps = await db.rawQuery('''
        SELECT name, COALESCE(current_stock, 0) as current_stock 
        FROM inventory_items
      ''');
      
      final stockMap = <int, int>{};
      for (final map in maps) {
        final name = map['name'] as String;
        final stock = (map['current_stock'] as num?)?.toInt() ?? 0;
        
        // Find matching catalog item by name
        for (final catalogItem in ItemCatalog.items) {
          if (catalogItem.name.toLowerCase() == name.toLowerCase()) {
            stockMap[catalogItem.id] = stock;
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