import 'package:flutter/foundation.dart';
import '../models/stock_movement_model.dart';
import '../models/inventory_item_model.dart'; // <-- use the canonical model
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();

  String _id = '';
  String _title = '';
  String _sku = '';
  double _currentStock = 0.0;
  double _reorderPoint = 0.0;
  double _avgCost = 0.0;
  String _category = '';
  String _unit = '';
  String _barcode = '';
  List<StockMovement> _movements = [];
  bool _isLoading = false;

  String get id => _id;
  String get title => _title;
  String get sku => _sku;
  double get currentStock => _currentStock;
  double get reorderPoint => _reorderPoint;
  double get avgCost => _avgCost;
  double get inventoryValue => _currentStock * _avgCost;
  String get category => _category;
  String get unit => _unit;
  String get barcode => _barcode;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;

  /// Load item and its movements from InventoryService
  Future<void> load(String itemId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final item = await _inventoryService.getItemById(itemId);
      if (item != null) {
        _id = item.id;
        _title = item.name;
        _sku = item.sku;
        _currentStock = item.currentStock ?? 0.0;
        _reorderPoint = item.reorderPoint ?? 0.0;
        _avgCost = item.avgCost ?? 0.0;
        _category = item.category ?? '';
        _unit = item.unit ?? 'pcs';
        _barcode = item.barcode ?? '';
        _movements = await _inventory_service_getMovementsSafe(itemId);
      } else {
        // item null — clear fields
        _id = '';
        _title = '';
        _sku = '';
        _currentStock = 0.0;
        _reorderPoint = 0.0;
        _avgCost = 0.0;
        _category = '';
        _unit = 'pcs';
        _barcode = '';
        _movements = [];
      }
    } catch (e) {
      debugPrint('Error loading item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<StockMovement>> _inventory_service_getMovementsSafe(String itemId) async {
    try {
      final ms = await _inventoryService.getMovementsByItem(itemId);
      return ms;
    } catch (e) {
      debugPrint('Error fetching movements: $e');
      return <StockMovement>[];
    }
  }

  /// Receive: increase stock. qty positive, cost >= 0
  Future<void> receive(double qty, double cost, {String? note}) async {
    if (qty <= 0) throw Exception('Quantity must be positive');
    if (cost < 0) throw Exception('Cost cannot be negative');

    try {
      final sourceRef = (note == null || note.isEmpty) ? 'manual:receive' : note;
      await _inventoryService.receiveStock(_id, qty, cost, sourceRef);
      await _refreshData();
    } catch (e) {
      debugPrint('Error receiving stock: $e');
      rethrow;
    }
  }

  /// Issue: decrease stock. qty positive
  Future<void> issue(double qty, {String? note}) async {
    if (qty <= 0) throw Exception('Quantity must be positive');

    try {
      final sourceRef = (note == null || note.isEmpty) ? 'manual:issue' : note;
      await _inventoryService.issueStock(_id, qty, sourceRef);
      await _refreshData();
    } catch (e) {
      debugPrint('Error issuing stock: $e');
      rethrow;
    }
  }

  /// Adjust: apply a delta to stock (pass positive to increase, negative to decrease).
  /// If you want to set an absolute stock, call adjust with delta = newStock - currentStock.
  Future<void> adjust(double delta, String reason, {bool override = false}) async {
    // delta can be negative or positive — allowNegative is controlled by override
    try {
      await _inventoryService.adjustStock(_id, delta, reason, allowNegative: override);
      await _refreshData();
    } catch (e) {
      debugPrint('Error adjusting stock: $e');
      rethrow;
    }
  }

  /// Update item metadata (title, sku, unit, category, reorderPoint, barcode)
  Future<void> updateItem({
    required String title,
    required String sku,
    required String unit,
    required String category,
    required double reorderPoint,
    String? barcode,
  }) async {
    if (_id.isEmpty) throw Exception('No item loaded');
    try {
      // Build the canonical InventoryItem (from models/inventory_item_model.dart)
      final updated = InventoryItem(
        id: _id,
        sku: sku,
        name: title,
        unit: unit,
        openingStock: 0.0,
        currentStock: _currentStock,
        reorderPoint: reorderPoint,
        avgCost: _avgCost,
        category: category,
        lastUpdated: DateTime.now(),
        barcode: barcode,
      );

      // InventoryService should implement updateItem and accept the canonical InventoryItem
      await _inventoryService.updateItem(updated);
      await _refreshData();
    } catch (e) {
      debugPrint('Error updating item: $e');
      rethrow;
    }
  }

  /// Delete item and all its movements
  Future<void> deleteItem() async {
    if (_id.isEmpty) throw Exception('No item loaded');
    try {
      await _inventoryService.deleteItem(_id);
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    try {
      final item = await _inventoryService.getItemById(_id);
      if (item != null) {
        _title = item.name;
        _sku = item.sku;
        _currentStock = item.currentStock ?? 0.0;
        _reorderPoint = item.reorderPoint ?? 0.0;
        _avgCost = item.avgCost ?? 0.0;
        _category = item.category ?? '';
        _unit = item.unit ?? 'pcs';
        _barcode = item.barcode ?? '';
        _movements = await _inventory_service_getMovementsSafe(_id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }
}
