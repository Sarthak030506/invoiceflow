import '../models/invoice_model.dart';
import '../models/return_model.dart';
import '../utils/app_logger.dart';
import './firestore_service.dart';
import './inventory_service.dart';
import './return_service.dart';

/// Service to handle invoice editing with comprehensive business logic
/// Handles inventory adjustments, payment reconciliation, and return validation
class EditInvoiceService {
  static EditInvoiceService? _instance;
  EditInvoiceService._internal();

  static EditInvoiceService get instance {
    _instance ??= EditInvoiceService._internal();
    return _instance!;
  }

  final FirestoreService _firestoreService = FirestoreService.instance;
  final InventoryService _inventoryService = InventoryService();
  final ReturnService _returnService = ReturnService.instance;

  /// Validates if an invoice can be edited
  /// Returns error message if cannot be edited, null if can be edited
  Future<String?> validateInvoiceCanBeEdited(InvoiceModel invoice) async {
    // Check if invoice is cancelled
    if (invoice.status.toLowerCase() == 'cancelled') {
      return 'Cannot edit a cancelled invoice';
    }

    // Check if invoice has linked returns
    final returns = await _returnService.getReturnsByInvoiceId(invoice.id);
    if (returns.isNotEmpty) {
      return 'Cannot edit invoice with linked returns. Please cancel returns first.';
    }

    return null; // Can be edited
  }

  /// Calculate inventory differences between old and new invoice
  Map<String, InventoryChange> _calculateInventoryChanges(
    InvoiceModel oldInvoice,
    InvoiceModel newInvoice,
  ) {
    final changes = <String, InventoryChange>{};

    // Create maps for quick lookup
    final oldItemsMap = <String, InvoiceItem>{};
    for (final item in oldInvoice.items) {
      oldItemsMap[item.name] = item;
    }

    final newItemsMap = <String, InvoiceItem>{};
    for (final item in newInvoice.items) {
      newItemsMap[item.name] = item;
    }

    // Find all unique item names
    final allItemNames = {...oldItemsMap.keys, ...newItemsMap.keys};

    for (final itemName in allItemNames) {
      final oldItem = oldItemsMap[itemName];
      final newItem = newItemsMap[itemName];

      final oldQty = oldItem?.quantity.toDouble() ?? 0.0;
      final newQty = newItem?.quantity.toDouble() ?? 0.0;

      if (oldQty != newQty) {
        changes[itemName] = InventoryChange(
          itemName: itemName,
          oldQuantity: oldQty,
          newQuantity: newQty,
          quantityDiff: newQty - oldQty,
        );
      }
    }

    return changes;
  }

  /// Validate inventory changes are possible
  Future<String?> _validateInventoryChanges(
    Map<String, InventoryChange> changes,
    String invoiceType,
  ) async {
    if (invoiceType != 'sales') {
      return null; // Only validate sales invoices for stock availability
    }

    for (final change in changes.values) {
      // If increasing quantity in sales invoice, check if stock is available
      if (change.quantityDiff > 0) {
        final item = await _inventoryService.getItemByName(change.itemName);
        if (item == null) {
          return 'Item "${change.itemName}" not found in inventory';
        }

        // Check if we have enough stock
        if (item.currentStock < change.quantityDiff) {
          return 'Insufficient stock for "${change.itemName}". Available: ${item.currentStock}, Required: ${change.quantityDiff}';
        }
      }
    }

    return null; // All validations passed
  }

  /// Apply inventory changes
  Future<void> _applyInventoryChanges(
    Map<String, InventoryChange> changes,
    String invoiceType,
    String invoiceNumber,
  ) async {
    for (final change in changes.values) {
      if (change.quantityDiff == 0) continue;

      // Get the item to find its ID
      final item = await _inventoryService.getItemByName(change.itemName);
      if (item == null) {
        throw StateError('Item "${change.itemName}" not found in inventory');
      }

      if (invoiceType == 'sales') {
        // Sales invoice: positive diff means more sold (decrease stock)
        //                negative diff means less sold (increase stock)
        if (change.quantityDiff > 0) {
          // Selling more - reduce stock
          await _inventoryService.adjustStock(
            item.id,
            -change.quantityDiff,
            'Edited invoice $invoiceNumber - increased quantity',
          );
        } else {
          // Selling less - add back to stock
          await _inventoryService.adjustStock(
            item.id,
            -change.quantityDiff, // Already negative, so this adds
            'Edited invoice $invoiceNumber - decreased quantity',
          );
        }
      } else {
        // Purchase invoice: positive diff means more purchased (increase stock)
        //                   negative diff means less purchased (decrease stock)
        await _inventoryService.adjustStock(
          item.id,
          change.quantityDiff,
          'Edited invoice $invoiceNumber - quantity adjusted',
        );
      }
    }
  }

  /// Calculate payment reconciliation details
  PaymentReconciliation _calculatePaymentReconciliation(
    InvoiceModel oldInvoice,
    InvoiceModel newInvoice,
  ) {
    final oldTotal = oldInvoice.adjustedTotal;
    final newTotal = newInvoice.adjustedTotal;
    final amountPaid = newInvoice.amountPaid;

    final oldRemaining = oldTotal - amountPaid;
    final newRemaining = newTotal - amountPaid;

    return PaymentReconciliation(
      oldTotal: oldTotal,
      newTotal: newTotal,
      amountPaid: amountPaid,
      oldRemaining: oldRemaining,
      newRemaining: newRemaining,
      totalChanged: oldTotal != newTotal,
      needsRefund: newRemaining < -0.01,
      needsPayment: newRemaining > 0.01,
      refundAmount: newRemaining < 0 ? -newRemaining : 0.0,
    );
  }

  /// Validate payment reconciliation
  String? _validatePaymentReconciliation(PaymentReconciliation reconciliation) {
    // If amount paid is now greater than new total, flag as refund due
    if (reconciliation.needsRefund) {
      // This is allowed - just flag it in the UI
      return null;
    }

    // All other cases are valid
    return null;
  }

  /// Main method to edit an invoice with full validation and adjustments
  Future<EditInvoiceResult> editInvoice({
    required InvoiceModel oldInvoice,
    required InvoiceModel newInvoice,
    required String editReason,
  }) async {
    try {
      // Step 1: Validate invoice can be edited
      final validationError = await validateInvoiceCanBeEdited(oldInvoice);
      if (validationError != null) {
        return EditInvoiceResult(
          success: false,
          errorMessage: validationError,
        );
      }

      // Step 2: Calculate inventory changes
      final inventoryChanges = _calculateInventoryChanges(oldInvoice, newInvoice);

      // Step 3: Validate inventory changes
      final inventoryError = await _validateInventoryChanges(
        inventoryChanges,
        newInvoice.invoiceType,
      );
      if (inventoryError != null) {
        return EditInvoiceResult(
          success: false,
          errorMessage: inventoryError,
        );
      }

      // Step 4: Calculate payment reconciliation
      final paymentReconciliation = _calculatePaymentReconciliation(
        oldInvoice,
        newInvoice,
      );

      // Step 5: Validate payment reconciliation
      final paymentError = _validatePaymentReconciliation(paymentReconciliation);
      if (paymentError != null) {
        return EditInvoiceResult(
          success: false,
          errorMessage: paymentError,
        );
      }

      // Step 6: Apply inventory changes
      if (inventoryChanges.isNotEmpty) {
        await _applyInventoryChanges(
          inventoryChanges,
          newInvoice.invoiceType,
          newInvoice.invoiceNumber,
        );
      }

      // Step 7: Update invoice with modification flags
      final updatedInvoice = newInvoice.copyWith(
        modifiedFlag: true,
        modifiedReason: editReason,
        modifiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        revenue: newInvoice.total.toDouble(), // Update revenue to match new total
      );

      // Step 8: Save updated invoice
      await _firestoreService.upsertInvoice(updatedInvoice);

      AppLogger.info('Invoice edited successfully: ${oldInvoice.id}', 'EditInvoiceService');

      return EditInvoiceResult(
        success: true,
        updatedInvoice: updatedInvoice,
        paymentReconciliation: paymentReconciliation,
        inventoryChanges: inventoryChanges,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to edit invoice', 'EditInvoiceService', e, stackTrace);
      return EditInvoiceResult(
        success: false,
        errorMessage: 'Failed to edit invoice: ${e.toString()}',
      );
    }
  }
}

/// Represents an inventory change for an item
class InventoryChange {
  final String itemName;
  final double oldQuantity;
  final double newQuantity;
  final double quantityDiff; // positive = increase, negative = decrease

  InventoryChange({
    required this.itemName,
    required this.oldQuantity,
    required this.newQuantity,
    required this.quantityDiff,
  });

  @override
  String toString() {
    return '$itemName: $oldQuantity → $newQuantity (${quantityDiff > 0 ? '+' : ''}$quantityDiff)';
  }
}

/// Payment reconciliation details
class PaymentReconciliation {
  final double oldTotal;
  final double newTotal;
  final double amountPaid;
  final double oldRemaining;
  final double newRemaining;
  final bool totalChanged;
  final bool needsRefund;
  final bool needsPayment;
  final double refundAmount;

  PaymentReconciliation({
    required this.oldTotal,
    required this.newTotal,
    required this.amountPaid,
    required this.oldRemaining,
    required this.newRemaining,
    required this.totalChanged,
    required this.needsRefund,
    required this.needsPayment,
    required this.refundAmount,
  });

  String get statusMessage {
    if (!totalChanged) {
      return 'Invoice total unchanged';
    }
    if (needsRefund) {
      return 'Refund due: ₹${refundAmount.toStringAsFixed(2)}';
    }
    if (needsPayment) {
      return 'Additional payment needed: ₹${newRemaining.toStringAsFixed(2)}';
    }
    return 'Fully paid';
  }
}

/// Result of invoice edit operation
class EditInvoiceResult {
  final bool success;
  final String? errorMessage;
  final InvoiceModel? updatedInvoice;
  final PaymentReconciliation? paymentReconciliation;
  final Map<String, InventoryChange>? inventoryChanges;

  EditInvoiceResult({
    required this.success,
    this.errorMessage,
    this.updatedInvoice,
    this.paymentReconciliation,
    this.inventoryChanges,
  });
}
