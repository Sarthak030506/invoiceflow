import 'dart:async';
import '../models/inventory_item_model.dart';

class InventoryNotificationService {
  static final InventoryNotificationService _instance = InventoryNotificationService._internal();
  factory InventoryNotificationService() => _instance;
  InventoryNotificationService._internal();

  final StreamController<List<InventoryItem>> _lowStockController = StreamController<List<InventoryItem>>.broadcast();
  final StreamController<InventoryItem> _itemUpdatedController = StreamController<InventoryItem>.broadcast();
  final StreamController<Map<String, dynamic>> _metricsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<InventoryItem>> get lowStockStream => _lowStockController.stream;
  Stream<InventoryItem> get itemUpdatedStream => _itemUpdatedController.stream;
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;

  void notifyLowStock(List<InventoryItem> lowStockItems) {
    _lowStockController.add(lowStockItems);
  }

  void notifyItemUpdated(InventoryItem item) {
    _itemUpdatedController.add(item);
  }

  void notifyMetricsUpdated(Map<String, dynamic> metrics) {
    _metricsController.add(metrics);
  }

  void dispose() {
    _lowStockController.close();
    _itemUpdatedController.close();
    _metricsController.close();
  }
}