import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';
import '../models/inventory_item_model.dart';
import './csv_invoice_service.dart';
import './inventory_service.dart';
import './firestore_service.dart';
import './analytics_service.dart';
import './customer_service.dart';
import '../utils/app_logger.dart';

class InvoiceService {
  // --- Start of Singleton Implementation ---
  static InvoiceService? _instance;

  // Private constructor. No one can create an instance of this from outside.
  InvoiceService._internal({required this.csvPath}) : _csvInvoiceService = CsvInvoiceService(assetPath: csvPath);

  // The static 'instance' getter. This is how you will access the service.
  static InvoiceService get instance {
    if (_instance == null) {
      throw StateError('InvoiceService not initialized. Call InvoiceService.initialize() first.');
    }
    return _instance!;
  }

  // A one-time setup method to be called from main().
  static Future<void> initialize({required String csvPath}) async {
    if (_instance != null) return; // Already initialized
    // Create the single instance.
    _instance = InvoiceService._internal(csvPath: csvPath);
    // Perform the one-time migration here, once, when the app starts.
    try {
      await _instance!._migrateCsvToDbIfNeeded();
    } catch (e) {
      AppLogger.warning('CSV migration failed but continuing', 'InvoiceService');
      // Continue even if migration fails - this allows web version to work
    }
  }

  String _sanitizeFirestoreId(String id) {
    // Replace characters not allowed or problematic in document IDs
    // Firestore allows most characters, but slashes create path segments.
    var safe = id.trim();
    if (safe.isEmpty) {
      return 'INV_${DateTime.now().millisecondsSinceEpoch}';
    }
    // Replace forward/back slashes and control whitespace with underscore
    safe = safe.replaceAll(RegExp(r"[\\/\n\r\t]"), '_');
    // Collapse multiple underscores
    safe = safe.replaceAll(RegExp(r'_+'), '_');
    // Limit length to a reasonable size
    if (safe.length > 150) {
      safe = safe.substring(0, 150);
    }
    return safe;
  }
  // --- End of Singleton Implementation ---

  final FirestoreService _fsService = FirestoreService.instance;
  final CsvInvoiceService _csvInvoiceService;
  final String csvPath;

  // This is the corrected, safer migration logic.
  Future<void> _migrateCsvToDbIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isMigrated = prefs.getBool('csv_migrated') ?? false;

    // If the migration has already run successfully, do nothing.
    if (isMigrated) {
      AppLogger.info('CSV migration already completed. Skipping.', 'Migration');
      return;
    }

    // If the flag is not set, perform the one-time migration.
    AppLogger.info('Starting one-time CSV migration...', 'Migration');
    try {
      final csvInvoices = await _csvInvoiceService.loadInvoicesFromCsv();
      AppLogger.info('Migrating ${csvInvoices.length} invoices from CSV...', 'Migration');

      int success = 0;
      int failed = 0;
      for (final original in csvInvoices) {
        try {
          // Sanitize ID to be Firestore-safe
          final safeId = _sanitizeFirestoreId(original.id);
          final safeNumber = original.invoiceNumber.isEmpty ? safeId : original.invoiceNumber;
          final inv = original.copyWith(id: safeId, invoiceNumber: safeNumber);
          await _fsService.upsertInvoice(inv);
          success++;
        } catch (e) {
          failed++;
          AppLogger.error('CSV migrate failed for invoice', 'Migration', e);
          // continue with next invoice
        }
      }

      if (failed == 0) {
        // Set the flag to true ONLY after successful migration of all records.
        await prefs.setBool('csv_migrated', true);
        AppLogger.info('CSV migration completed successfully', 'Migration');
      } else {
        AppLogger.warning('CSV migration partially completed', 'Migration');
        // Leave flag false to retry or handle later
      }
    } catch (e) {
      AppLogger.error('CSV migration failed', 'Migration', e);
      // Do NOT set the flag if it fails, so it can try again on the next launch.
    }
  }

  // --- Update all data-fetching methods to REMOVE the migration call ---

  Future<List<InvoiceModel>> fetchRecentInvoices() async {
    return await _fsService.getRecentInvoices(limit: 5);
  }

  Future<List<InvoiceModel>> fetchAllInvoices() async {
    return await _fsService.getAllInvoices();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _fsService.upsertInvoice(invoice);
    if (invoice.status == 'posted') {
      await _processInvoiceInventory(invoice);
    }
    // Invalidate analytics cache when invoices change
    await AnalyticsService().invalidateCache();

    // Update denormalized customer stats for fast queries
    if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
      try {
        await CustomerService.instance.updateCustomerStats(invoice.customerId!);
      } catch (e) {
        AppLogger.warning('Failed to update customer stats', 'InvoiceService');
      }
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final oldInvoice = await _fsService.getInvoice(invoice.id);
    await _fsService.upsertInvoice(invoice);

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
    // Invalidate analytics cache when invoices change
    await AnalyticsService().invalidateCache();

    // Update denormalized customer stats
    if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
      try {
        await CustomerService.instance.updateCustomerStats(invoice.customerId!);
      } catch (e) {
        AppLogger.warning('Failed to update customer stats', 'InvoiceService');
      }
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final invoice = await _fsService.getInvoiceById(invoiceId);
    if (invoice == null) return;

    if (invoice.status == 'posted') {
      if (invoice.invoiceType == 'purchase') {
        // Delegate to cancellation flow which validates and reverses as needed
        await cancelInvoice(invoiceId);
      } else if (invoice.invoiceType == 'sales') {
        // Reverse issued stock for posted sales before delete
        await _reverseInvoiceInventory(invoice);
        await _fsService.deleteInvoice(invoiceId);
      } else {
        await _fsService.deleteInvoice(invoiceId);
      }
    } else {
      await _fsService.deleteInvoice(invoiceId);
    }
    // Invalidate analytics cache when invoices change
    await AnalyticsService().invalidateCache();
  }

  /// Gets invoice by ID
  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    return await _fsService.getInvoice(invoiceId);
  }

  /// Check if an invoice number already exists
  Future<bool> isInvoiceNumberExists(String invoiceNumber) async {
    return await _fsService.isInvoiceNumberExists(invoiceNumber);
  }

  /// Generate next sequential invoice number
  Future<String> generateNextInvoiceNumber() async {
    return await _fsService.generateNextInvoiceNumber();
  }

  /// Validates if an invoice can be cancelled safely
  Future<Map<String, dynamic>> validateInvoiceCancellation(String invoiceId) async {
    final invoice = await _fsService.getInvoice(invoiceId);
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
    final invoice = await _fsService.getInvoice(invoiceId);
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
    
    await _fsService.upsertInvoice(cancelledInvoice);
  }

  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    // Fetch last 90 days of invoices for dashboard metrics (scalable approach)
    final startDate = DateTime.now().subtract(Duration(days: 90));
    final invoices = await _fsService.getInvoicesByDateRange(
      startDate: startDate,
      limit: 1000, // Reasonable limit for dashboard
    );

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
        AppLogger.error('Inventory processing error', 'Invoice', e);
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
        AppLogger.error('Return inventory processing error', 'Invoice', e);
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
        AppLogger.error('Adjustment inventory processing error', 'Invoice', e);
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
    final invoice = await _fsService.getInvoice(invoiceId);
    if (invoice == null) return;
    
    final modifiedInvoice = invoice.copyWith(
      modifiedFlag: true,
      modifiedReason: reason,
      modifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _fsService.upsertInvoice(modifiedInvoice);
  }

  Future<void> markLastThreeInvoicesUnpaid() async {
    final invoices = await _fsService.getAllInvoices();
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
          await _fsService.upsertInvoice(updatedInvoice);
        }
      }
    }
  }
}