import 'package:flutter_test/flutter_test.dart';
import '../lib/services/invoice_service.dart';
import '../lib/services/inventory_service.dart';
import '../lib/models/invoice_model.dart';
import '../lib/models/inventory_item_model.dart';

void main() {
  group('Inventory Integration Tests', () {
    late InvoiceService invoiceService;
    late InventoryService inventoryService;

    setUp(() async {
      // Initialize services
      await InvoiceService.initialize(csvPath: 'assets/invoices.csv');
      invoiceService = InvoiceService.instance;
      inventoryService = InventoryService();
    });

    test('Purchase invoice increases stock', () async {
      // Create test item
      final testItem = InventoryItem(
        id: 'test_item_1',
        sku: 'TEST001',
        name: 'Test Product',
        unit: 'pcs',
        openingStock: 10.0,
        currentStock: 10.0,
        reorderPoint: 5.0,
        avgCost: 100.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Create purchase invoice
      final purchaseInvoice = InvoiceModel(
        id: 'test_purchase_1',
        invoiceNumber: 'PUR001',
        clientName: 'Test Supplier',
        date: DateTime.now(),
        revenue: 500.0,
        status: 'posted',
        items: [
          InvoiceItem(name: 'Test Product', quantity: 5, price: 100.0),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        invoiceType: 'purchase',
      );

      await invoiceService.addInvoice(purchaseInvoice);

      // Verify stock increased
      final updatedItem = await inventoryService.getItemById('test_item_1');
      expect(updatedItem?.currentStock, equals(15.0));
    });

    test('Sales invoice decreases stock', () async {
      // Create test item with sufficient stock
      final testItem = InventoryItem(
        id: 'test_item_2',
        sku: 'TEST002',
        name: 'Test Product 2',
        unit: 'pcs',
        openingStock: 20.0,
        currentStock: 20.0,
        reorderPoint: 5.0,
        avgCost: 50.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Create sales invoice
      final salesInvoice = InvoiceModel(
        id: 'test_sales_1',
        invoiceNumber: 'SAL001',
        clientName: 'Test Customer',
        date: DateTime.now(),
        revenue: 300.0,
        status: 'posted',
        items: [
          InvoiceItem(name: 'Test Product 2', quantity: 6, price: 50.0),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        invoiceType: 'sales',
      );

      await invoiceService.addInvoice(salesInvoice);

      // Verify stock decreased
      final updatedItem = await inventoryService.getItemById('test_item_2');
      expect(updatedItem?.currentStock, equals(14.0));
    });

    test('Sales return increases stock', () async {
      // Create test item
      final testItem = InventoryItem(
        id: 'test_item_3',
        sku: 'TEST003',
        name: 'Test Product 3',
        unit: 'pcs',
        openingStock: 10.0,
        currentStock: 10.0,
        reorderPoint: 5.0,
        avgCost: 75.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Process sales return
      await invoiceService.processReturnInventory(
        'return_001',
        'sales_return',
        [InvoiceItem(name: 'Test Product 3', quantity: 3, price: 75.0)],
      );

      // Verify stock increased
      final updatedItem = await inventoryService.getItemById('test_item_3');
      expect(updatedItem?.currentStock, equals(13.0));
    });

    test('Purchase return decreases stock', () async {
      // Create test item with sufficient stock
      final testItem = InventoryItem(
        id: 'test_item_4',
        sku: 'TEST004',
        name: 'Test Product 4',
        unit: 'pcs',
        openingStock: 15.0,
        currentStock: 15.0,
        reorderPoint: 5.0,
        avgCost: 80.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Process purchase return
      await invoiceService.processReturnInventory(
        'return_002',
        'purchase_return',
        [InvoiceItem(name: 'Test Product 4', quantity: 4, price: 80.0)],
      );

      // Verify stock decreased
      final updatedItem = await inventoryService.getItemById('test_item_4');
      expect(updatedItem?.currentStock, equals(11.0));
    });

    test('Stock adjustment works correctly', () async {
      // Create test item
      final testItem = InventoryItem(
        id: 'test_item_5',
        sku: 'TEST005',
        name: 'Test Product 5',
        unit: 'pcs',
        openingStock: 12.0,
        currentStock: 12.0,
        reorderPoint: 5.0,
        avgCost: 60.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Process positive adjustment
      await inventoryService.adjustStock('test_item_5', 8.0, 'Stock count correction');

      // Verify stock increased
      var updatedItem = await inventoryService.getItemById('test_item_5');
      expect(updatedItem?.currentStock, equals(20.0));

      // Process negative adjustment
      await inventoryService.adjustStock('test_item_5', -5.0, 'Damaged goods removal');

      // Verify stock decreased
      updatedItem = await inventoryService.getItemById('test_item_5');
      expect(updatedItem?.currentStock, equals(15.0));
    });

    test('Insufficient stock prevents sales', () async {
      // Create test item with low stock
      final testItem = InventoryItem(
        id: 'test_item_6',
        sku: 'TEST006',
        name: 'Test Product 6',
        unit: 'pcs',
        openingStock: 3.0,
        currentStock: 3.0,
        reorderPoint: 5.0,
        avgCost: 90.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Try to issue more stock than available
      expect(
        () => inventoryService.issueStock('test_item_6', 5.0, 'test:001'),
        throwsException,
      );

      // Verify stock unchanged
      final updatedItem = await inventoryService.getItemById('test_item_6');
      expect(updatedItem?.currentStock, equals(3.0));
    });

    test('Draft invoices do not affect inventory', () async {
      // Create test item
      final testItem = InventoryItem(
        id: 'test_item_7',
        sku: 'TEST007',
        name: 'Test Product 7',
        unit: 'pcs',
        openingStock: 10.0,
        currentStock: 10.0,
        reorderPoint: 5.0,
        avgCost: 70.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Create draft invoice
      final draftInvoice = InvoiceModel(
        id: 'test_draft_1',
        invoiceNumber: 'DRAFT001',
        clientName: 'Test Customer',
        date: DateTime.now(),
        revenue: 210.0,
        status: 'draft', // Draft status
        items: [
          InvoiceItem(name: 'Test Product 7', quantity: 3, price: 70.0),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        invoiceType: 'sales',
      );

      await invoiceService.addInvoice(draftInvoice);

      // Verify stock unchanged
      final updatedItem = await inventoryService.getItemById('test_item_7');
      expect(updatedItem?.currentStock, equals(10.0));
    });

    test('Posting draft invoice affects inventory', () async {
      // Create test item
      final testItem = InventoryItem(
        id: 'test_item_8',
        sku: 'TEST008',
        name: 'Test Product 8',
        unit: 'pcs',
        openingStock: 15.0,
        currentStock: 15.0,
        reorderPoint: 5.0,
        avgCost: 85.0,
        category: 'Test',
        lastUpdated: DateTime.now(),
      );
      await inventoryService.addItem(testItem);

      // Create and add draft invoice
      final draftInvoice = InvoiceModel(
        id: 'test_draft_2',
        invoiceNumber: 'DRAFT002',
        clientName: 'Test Customer',
        date: DateTime.now(),
        revenue: 340.0,
        status: 'draft',
        items: [
          InvoiceItem(name: 'Test Product 8', quantity: 4, price: 85.0),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        invoiceType: 'sales',
      );

      await invoiceService.addInvoice(draftInvoice);

      // Verify stock unchanged initially
      var updatedItem = await inventoryService.getItemById('test_item_8');
      expect(updatedItem?.currentStock, equals(15.0));

      // Post the invoice
      final postedInvoice = draftInvoice.copyWith(status: 'posted');
      await invoiceService.updateInvoice(postedInvoice);

      // Verify stock decreased after posting
      updatedItem = await inventoryService.getItemById('test_item_8');
      expect(updatedItem?.currentStock, equals(11.0));
    });
  });
}