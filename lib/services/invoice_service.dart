import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';
import '../models/inventory_item_model.dart';
import './database_service.dart';
import './csv_invoice_service.dart';
import './inventory_service.dart';

class InvoiceService {
  // --- Start of Singleton Implementation ---
  static late final InvoiceService _instance;

  // Private constructor. No one can create an instance of this from outside.
  InvoiceService._internal({required this.csvPath}) : _csvInvoiceService = CsvInvoiceService(assetPath: csvPath);

  // The static 'instance' getter. This is how you will access the service.
  static InvoiceService get instance => _instance;

  // A one-time setup method to be called from main().
  static Future<void> initialize({required String csvPath}) async {
    // Create the single instance.
    _instance = InvoiceService._internal(csvPath: csvPath);
    // Perform the one-time migration here, once, when the app starts.
    await _instance._migrateCsvToDbIfNeeded();
  }
  // --- End of Singleton Implementation ---

  final DatabaseService _dbService = DatabaseService();
  final CsvInvoiceService _csvInvoiceService;
  final String csvPath;

  // This is the corrected, safer migration logic.
  Future<void> _migrateCsvToDbIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isMigrated = prefs.getBool('csv_migrated') ?? false;

    // If the migration has already run successfully, do nothing.
    if (isMigrated) {
      print('CSV migration already completed. Skipping.');
      return;
    }

    // If the flag is not set, perform the one-time migration.
    print('Starting one-time CSV migration...');
    try {
      final csvInvoices = await _csvInvoiceService.loadInvoicesFromCsv();
      print('Migrating ${csvInvoices.length} invoices from CSV...');
      
      for (final invoice in csvInvoices) {
        await _dbService.insertInvoice(invoice);
      }
      
      // IMPORTANT: Set the flag to true ONLY after a successful migration.
      await prefs.setBool('csv_migrated', true);
      print('CSV migration completed successfully.');
    } catch (e) {
      print('CSV migration failed: $e');
      // Do NOT set the flag if it fails, so it can try again on the next launch.
    }
  }

  // --- Update all data-fetching methods to REMOVE the migration call ---

  Future<List<InvoiceModel>> fetchRecentInvoices() async {
    return await _dbService.getRecentInvoices(limit: 5);
  }

  Future<List<InvoiceModel>> fetchAllInvoices() async {
    return await _dbService.getAllInvoices();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _dbService.insertInvoice(invoice);
    if (invoice.status == 'posted') {
      await _processInvoiceInventory(invoice);
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final oldInvoice = await _dbService.getInvoiceById(invoice.id);
    await _dbService.updateInvoice(invoice);
    
    // Handle status changes that affect inventory
    if (oldInvoice != null) {
      final wasPosted = oldInvoice.status == 'posted';
      final isPosted = invoice.status == 'posted';
      
      if (!wasPosted && isPosted) {
        // Invoice was just posted - process inventory
        await _processInvoiceInventory(invoice);
      } else if (wasPosted && !isPosted) {
        // Invoice was unposted - reverse inventory
        await _reverseInvoiceInventory(invoice);
      }
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final invoice = await _dbService.getInvoiceById(invoiceId);
    if (invoice == null) return;
    
    if (invoice.status == 'posted' && invoice.invoiceType == 'purchase') {
      await cancelInvoice(invoiceId);
    } else {
      await _dbService.deleteInvoice(invoiceId);
    }
  }

  /// Gets invoice by ID
  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    return await _dbService.getInvoiceById(invoiceId);
  }

  /// Validates if an invoice can be cancelled safely
  Future<Map<String, dynamic>> validateInvoiceCancellation(String invoiceId) async {
    final invoice = await _dbService.getInvoiceById(invoiceId);
    if (invoice == null) {
      return {'canCancel': false, 'error': 'Invoice not found'};
    }
    
    if (invoice.status == 'cancelled') {
      return {'canCancel': false, 'error': 'Invoice already cancelled'};
    }
    
    if (invoice.invoiceType != 'purchase') {
      return {'canCancel': true}; // Sales invoices can always be cancelled
    }
    
    final inventoryService = InventoryService();
    return await inventoryService.validateInvoiceCancellation('invoice', invoiceId);
  }

  Future<void> cancelInvoice(String invoiceId, {bool adminOverride = false, String? adminReason}) async {
    final invoice = await _dbService.getInvoiceById(invoiceId);
    if (invoice == null || invoice.status == 'cancelled') return;
    
    // Validate cancellation for purchase invoices
    if (invoice.invoiceType == 'purchase') {
      final inventoryService = InventoryService();
      
      if (!adminOverride) {
        final validation = await inventoryService.validateInvoiceCancellation('invoice', invoiceId);
        
        if (!validation['canCancel']) {
          final issues = validation['negativeStockIssues'] as List<Map<String, dynamic>>;
          final dependents = validation['dependentDocuments'] as List<String>;
          
          String errorMessage = 'Cannot cancel: ';
          
          if (issues.isNotEmpty) {
            errorMessage += 'insufficient on-hand due to subsequent issues. ';
            errorMessage += 'Items affected: ${issues.map((i) => i['itemName']).join(', ')}. ';
            errorMessage += 'Resolve by issuing return-in, or adjust stock, then retry.';
          }
          
          if (dependents.isNotEmpty) {
            if (issues.isNotEmpty) errorMessage += ' Also, ';
            errorMessage += 'dependent documents exist: ${dependents.join(', ')}. ';
            errorMessage += 'Reverse dependents first or post a compensating adjustment.';
          }
          
          throw Exception(errorMessage);
        }
        
        // Safe to cancel - no issues
        await inventoryService.reverseInvoiceMovements('invoice', invoiceId);
      } else {
        // Admin override - allow with adjustments
        if (adminReason == null || adminReason.trim().isEmpty) {
          throw Exception('Admin reason required for override cancellation');
        }
        
        await inventoryService.cancelInvoiceWithOverride('invoice', invoiceId, adminReason);
      }
    }
    
    // Update invoice status to cancelled with audit info
    final cancelledInvoice = invoice.copyWith(
      status: 'cancelled',
      updatedAt: DateTime.now(),
      cancelledAt: DateTime.now(),
      cancelReason: adminOverride ? 'Admin override: $adminReason' : 'Standard cancellation',
    );
    
    await _dbService.updateInvoice(cancelledInvoice);
  }

  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    final invoices = await _dbService.getAllInvoices();
    double totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.revenue);
    int totalItemsSold = invoices.fold(0, (sum, inv) => sum + inv.items.fold(0, (s, item) => s + item.quantity));
    int totalInvoices = invoices.length;
    return {
      "totalItemsSold": totalItemsSold,
      "totalRevenue": totalRevenue,
      "totalInvoices": totalInvoices,
      "itemsSoldChange": 0.0,
      "revenueChange": 0.0,
      "invoicesChange": 0.0,
      "lastUpdated": DateTime.now().toIso8601String(),
    };
  }

  Future<bool> validateGoogleSheetsConnection() async {
    return true;
  }

  /// Cancels invoice with admin override (for negative stock scenarios)
  Future<void> cancelInvoiceWithAdminOverride(String invoiceId, String adminReason) async {
    await cancelInvoice(invoiceId, adminOverride: true, adminReason: adminReason);
  }

  Future<void> _processInvoiceInventory(InvoiceModel invoice) async {
    final inventoryService = InventoryService();
    
    for (final item in invoice.items) {
      final itemId = _generateItemId(item.name);
      
      // Check if item exists in inventory by ID first, then by name as fallback
      InventoryItem? existingItem = await inventoryService.getItemById(itemId);
      
      // If not found by new ID, try to find by name (for legacy items with hash-based IDs)
      if (existingItem == null) {
        final allItems = await inventoryService.getAllItems();
        existingItem = allItems.cast<InventoryItem?>().firstWhere(
          (i) => i?.name.toLowerCase().trim() == item.name.toLowerCase().trim(),
          orElse: () => null,
        );
      }
      
      String finalItemId = itemId;
      if (existingItem != null) {
        // Use the existing item's ID to maintain consistency
        finalItemId = existingItem.id;
      } else {
        // Create new item with consistent ID
        final newItem = InventoryItem(
          id: itemId,
          sku: itemId.toUpperCase(),
          name: item.name,
          unit: 'pcs',
          openingStock: 0.0,
          currentStock: 0.0,
          reorderPoint: 10.0,
          avgCost: item.price,
          category: 'General',
          lastUpdated: DateTime.now(),
        );
        await inventoryService.addItem(newItem);
      }
      
      // Process stock movement
      try {
        if (invoice.invoiceType == 'purchase') {
          // Purchase invoice: increase stock
          await inventoryService.receiveStock(finalItemId, item.quantity.toDouble(), item.price, 'invoice:${invoice.id}');
        } else if (invoice.invoiceType == 'sales') {
          // Sales invoice: decrease stock
          await inventoryService.issueStock(finalItemId, item.quantity.toDouble(), 'invoice:${invoice.id}');
        }
      } catch (e) {
        print('Inventory processing error for ${item.name}: $e');
        rethrow;
      }
    }
  }



  Future<void> processReturnInventory(String returnId, String returnType, List<InvoiceItem> items, {String? originalInvoiceId}) async {
    final inventoryService = InventoryService();
    
    for (final item in items) {
      final itemId = _generateItemId(item.name);
      
      // Ensure item exists in inventory
      final existingItem = await inventoryService.getItemById(itemId);
      if (existingItem == null) {
        final newItem = InventoryItem(
          id: itemId,
          sku: itemId.toUpperCase(),
          name: item.name,
          unit: 'pcs',
          openingStock: 0.0,
          currentStock: 0.0,
          reorderPoint: 10.0,
          avgCost: item.price,
          category: 'General',
          lastUpdated: DateTime.now(),
        );
        await inventoryService.addItem(newItem);
      }
      
      try {
        if (returnType == 'sales_return') {
          await inventoryService.receiveStock(itemId, item.quantity.toDouble(), item.price, 'return:$returnId');
        } else if (returnType == 'purchase_return') {
          await inventoryService.issueStock(itemId, item.quantity.toDouble(), 'return:$returnId');
        }
      } catch (e) {
        print('Return inventory processing error for ${item.name}: $e');
        rethrow;
      }
    }
    
    // Mark original invoice as modified if provided
    if (originalInvoiceId != null) {
      await markInvoiceAsModified(originalInvoiceId, 'Return processed');
    }
  }

  Future<void> processAdjustmentInventory(String adjustmentId, List<Map<String, dynamic>> adjustments) async {
    final inventoryService = InventoryService();
    
    for (final adjustment in adjustments) {
      final itemId = adjustment['itemId'] as String;
      final deltaQty = adjustment['deltaQuantity'] as double;
      final reason = adjustment['reason'] as String;
      
      try {
        await inventoryService.adjustStock(itemId, deltaQty, 'adjustment:$adjustmentId - $reason');
      } catch (e) {
        print('Adjustment inventory processing error for item $itemId: $e');
        rethrow;
      }
    }
  }

  Future<void> _reverseInvoiceInventory(InvoiceModel invoice) async {
    final inventoryService = InventoryService();
    await inventoryService.reverseInvoiceMovements('invoice', invoice.id);
  }

  String _generateItemId(String itemName) {
    // Create a consistent ID based on cleaned item name only
    final cleanName = itemName.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    // Remove multiple underscores and trailing underscores
    final finalName = cleanName.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return finalName.isEmpty ? 'item_${DateTime.now().millisecondsSinceEpoch}' : finalName;
  }

  Future<void> markInvoiceAsModified(String invoiceId, String reason) async {
    final invoice = await _dbService.getInvoiceById(invoiceId);
    if (invoice == null) return;
    
    final modifiedInvoice = invoice.copyWith(
      modifiedFlag: true,
      modifiedReason: reason,
      modifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _dbService.updateInvoice(modifiedInvoice);
  }

  Future<void> markLastThreeInvoicesUnpaid() async {
    final invoices = await _dbService.getAllInvoices();
    if (invoices.length >= 3) {
      final lastThree = invoices.take(3).toList();
      
      for (final invoice in lastThree) {
        if (invoice.invoiceType == 'sales') {
          final updatedInvoice = invoice.copyWith(
            amountPaid: 0.0,
            status: 'pending',
            followUpDate: null,
            updatedAt: DateTime.now(),
          );
          await _dbService.updateInvoice(updatedInvoice);
        }
      }
    }
  }
}