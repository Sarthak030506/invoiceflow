import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceflow/services/inventory_service.dart';
import 'package:invoiceflow/models/inventory_item_model.dart';

void main() {
  group('Item Picker Performance Tests', () {
    late InventoryService inventoryService;
    // Local InventoryDatabase removed; tests run against Firestore-backed InventoryService

    setUpAll(() async {
      inventoryService = InventoryService();
      // No local DB to clean up
    });

    test('getItemsForPicker handles items with no stock records', () async {
      // Create a test item with no stock movements
      final testItem = InventoryItem(
        id: 'test_item_1',
        name: 'Test Item',
        sku: 'TEST001',
        category: 'Test',
        unit: 'pcs',
        avgCost: 8.0,
        openingStock: 0.0,
        currentStock: 0.0,
        reorderPoint: 5.0,
        barcode: '',
        lastUpdated: DateTime.now(),
      );

      await inventoryService.addItem(testItem);

      // Get items for picker
      final items = await inventoryService.getItemsForPicker();
      
      expect(items.isNotEmpty, true);
      final testItemData = items.firstWhere((item) => item['id'] == 'test_item_1');
      
      // Should default to 0.0 for stock
      expect(testItemData['current_stock'], 0.0);
      expect(testItemData['sell_price'], 8.0);
    });

    test('createItemFromInvoice creates new item and appears in picker', () async {
      // Simulate creating a new item from a purchase invoice
      final itemData = {
        'name': 'New Purchase Item',
        'rate': 15.0,
        'sku': 'NEW001',
        'category': 'New Category',
        'unit': 'kg',
        'barcode': '123456789',
      };

      final newItem = await inventoryService.createItemFromInvoice(itemData);
      
      // Verify item was created
      expect(newItem.name, 'New Purchase Item');
      expect(newItem.avgCost, 15.0);
      expect(newItem.currentStock, 0.0);

      // Simulate receiving stock for this new item
      await inventoryService.receiveStock(newItem.id, 10.0, 15.0, 'invoice:TEST001');

      // Verify it appears in picker with correct stock
      final items = await inventoryService.getItemsForPicker();
      final newItemData = items.firstWhere((item) => item['id'] == newItem.id);
      
      expect(newItemData['current_stock'], 10.0);
      expect(newItemData['name'], 'New Purchase Item');
    });

    test('stock cache handles missing stock gracefully', () async {
      // Create item with null stock values to test edge case
      final testItem = InventoryItem(
        id: 'edge_case_item',
        name: 'Edge Case Item',
        sku: 'EDGE001',
        category: 'Test',
        unit: 'pcs',
        avgCost: 0.0,
        openingStock: 0.0,
        currentStock: 0.0,
        reorderPoint: 0.0,
        barcode: '',
        lastUpdated: DateTime.now(),
      );

      await inventoryService.addItem(testItem);

      final items = await inventoryService.getItemsForPicker();
      final edgeItem = items.firstWhere((item) => item['id'] == 'edge_case_item');
      
      // Should handle zero/null values gracefully
      expect(edgeItem['current_stock'], 0.0);
      expect(edgeItem['sell_price'], 0.0);
    });

    test('performance with large dataset simulation', () async {
      final stopwatch = Stopwatch()..start();
      
      // Create multiple items to simulate larger dataset
      for (int i = 0; i < 50; i++) {
        final item = InventoryItem(
          id: 'perf_item_$i',
          name: 'Performance Item $i',
          sku: 'PERF${i.toString().padLeft(3, '0')}',
          category: i % 5 == 0 ? 'Kitchen' : 'General',
          unit: 'pcs',
          avgCost: 8.0 + i,
          openingStock: i.toDouble(),
          currentStock: i.toDouble(),
          reorderPoint: 5.0,
          barcode: '',
          lastUpdated: DateTime.now(),
        );
        await inventoryService.addItem(item);
      }

      // Test getItemsForPicker performance
      final items = await inventoryService.getItemsForPicker();
      stopwatch.stop();

      expect(items.length, greaterThanOrEqualTo(50));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      
      // Verify all items have proper stock values
      for (final item in items) {
        expect(item['current_stock'], isA<double>());
        expect(item['sell_price'], isA<double>());
        expect(item['current_stock'], greaterThanOrEqualTo(0.0));
      }
    });

    tearDownAll(() async {
      // No local DB teardown required
    });
  });
}