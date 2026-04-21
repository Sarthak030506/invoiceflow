import '../models/return_model.dart';
import './firestore_service.dart';
import './customer_service.dart';
import './inventory_service.dart';
import './analytics_service.dart';
import '../utils/app_logger.dart';

class ReturnValidationException implements Exception {
  final String message;
  const ReturnValidationException(this.message);
  @override
  String toString() => 'ReturnValidationException: $message';
}

class ReturnService {
  // Singleton implementation
  static ReturnService? _instance;

  ReturnService._internal();

  static ReturnService get instance {
    _instance ??= ReturnService._internal();
    return _instance!;
  }

  final FirestoreService _fsService = FirestoreService.instance;
  final CustomerService _customerService = CustomerService.instance;
  final InventoryService _inventoryService = InventoryService();

  // Guards against same-device double-tap / concurrent in-flight calls.
  // Reset in finally so a failed first call allows a user retry.
  bool _applyInProgress = false;

  // Generate unique return number
  Future<String> generateReturnNumber(String returnType) async {
    final prefix = returnType == 'sales' ? 'SR' : 'PR';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp';
  }

  // Create a new return
  Future<void> createReturn(ReturnModel returnModel) async {
    try {
      // --- Validation ---
      final invoice = await _fsService.getInvoice(returnModel.invoiceId);
      if (invoice == null) {
        throw ReturnValidationException(
          'Original invoice ${returnModel.invoiceId} not found.',
        );
      }

      // Build a lookup map of invoiced quantities by item name
      final invoicedQty = <String, int>{};
      for (final item in invoice.items) {
        invoicedQty[item.name] = (invoicedQty[item.name] ?? 0) + item.quantity;
      }

      for (final returnItem in returnModel.items) {
        final available = invoicedQty[returnItem.name] ?? 0;
        if (returnItem.quantity > available) {
          throw ReturnValidationException(
            'Return quantity ${returnItem.quantity} for "${returnItem.name}" '
            'exceeds invoiced quantity $available.',
          );
        }
      }

      if (returnModel.refundAmount > invoice.adjustedTotal + 0.001) {
        throw ReturnValidationException(
          'Refund amount ₹${returnModel.refundAmount.toStringAsFixed(2)} '
          'exceeds invoice adjustedTotal ₹${invoice.adjustedTotal.toStringAsFixed(2)}.',
        );
      }
      // --- End Validation ---

      await _fsService.createReturn(returnModel);

      // If it's a sales return, update customer's pending return amount
      if (returnModel.returnType == 'sales' && returnModel.customerId != null) {
        await _customerService.addPendingReturn(
          returnModel.customerId!,
          returnModel.refundAmount,
        );
      }

      // Update inventory for returned items
      await _processReturnInventory(returnModel);

      // Invalidate analytics cache when returns are created
      await AnalyticsService().invalidateCache();

      AppLogger.info('Return created successfully: ${returnModel.returnNumber}', 'ReturnService');
    } catch (e) {
      AppLogger.error('Failed to create return', 'ReturnService', e);
      rethrow;
    }
  }

  // Process inventory adjustments for returned items
  Future<void> _processReturnInventory(ReturnModel returnModel) async {
    try {
      for (final returnItem in returnModel.items) {
        // Find inventory item by name
        final inventoryItem = await _inventoryService.getItemByName(returnItem.name);

        if (inventoryItem != null) {
          if (returnModel.returnType == 'sales') {
            // Sales return: Add stock back (receiveStock)
            await _inventoryService.receiveStock(
              inventoryItem.id,
              returnItem.quantity.toDouble(),
              returnItem.price,
              'return:${returnModel.returnNumber}',
            );
            AppLogger.debug(
              'Sales return: Added ${returnItem.quantity} units of ${returnItem.name} back to inventory',
              'ReturnService',
            );
          } else if (returnModel.returnType == 'purchase') {
            // Purchase return: Remove stock (issueStock)
            await _inventoryService.issueStock(
              inventoryItem.id,
              returnItem.quantity.toDouble(),
              'return:${returnModel.returnNumber}',
            );
            AppLogger.debug(
              'Purchase return: Removed ${returnItem.quantity} units of ${returnItem.name} from inventory',
              'ReturnService',
            );
          }
        } else {
          AppLogger.warning(
            'Inventory item not found for return item: ${returnItem.name}',
            'ReturnService',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to process return inventory', 'ReturnService', e);
      // Don't rethrow - we still want the return to be created even if inventory update fails
    }
  }

  // Get all returns
  Future<List<ReturnModel>> getAllReturns() async {
    try {
      return await _fsService.getReturns();
    } catch (e) {
      AppLogger.error('Failed to get returns', 'ReturnService', e);
      return [];
    }
  }

  // Get returns by type (sales or purchase)
  Future<List<ReturnModel>> getReturnsByType(String returnType) async {
    try {
      return await _fsService.getReturnsByType(returnType);
    } catch (e) {
      AppLogger.error('Failed to get returns by type', 'ReturnService', e);
      return [];
    }
  }

  // Get return by ID
  Future<ReturnModel?> getReturnById(String id) async {
    try {
      return await _fsService.getReturnById(id);
    } catch (e) {
      AppLogger.error('Failed to get return by ID', 'ReturnService', e);
      return null;
    }
  }

  // Get returns by customer ID
  Future<List<ReturnModel>> getReturnsByCustomerId(String customerId) async {
    try {
      return await _fsService.getReturnsByCustomerId(customerId);
    } catch (e) {
      AppLogger.error('Failed to get returns by customer ID', 'ReturnService', e);
      return [];
    }
  }

  // Get returns by invoice ID
  Future<List<ReturnModel>> getReturnsByInvoiceId(String invoiceId) async {
    try {
      return await _fsService.getReturnsByInvoiceId(invoiceId);
    } catch (e) {
      AppLogger.error('Failed to get returns by invoice ID', 'ReturnService', e);
      return [];
    }
  }

  // Update return
  Future<void> updateReturn(ReturnModel returnModel) async {
    try {
      await _fsService.updateReturn(returnModel);
      AppLogger.info('Return updated successfully: ${returnModel.returnNumber}', 'ReturnService');
    } catch (e) {
      AppLogger.error('Failed to update return', 'ReturnService', e);
      rethrow;
    }
  }

  // Mark return as applied (when used in invoice)
  Future<void> markReturnAsApplied(String returnId) async {
    try {
      final returnModel = await getReturnById(returnId);
      if (returnModel != null) {
        final updatedReturn = returnModel.copyWith(
          isApplied: true,
          updatedAt: DateTime.now(),
        );
        await updateReturn(updatedReturn);
      }
    } catch (e) {
      AppLogger.error('Failed to mark return as applied', 'ReturnService', e);
      rethrow;
    }
  }

  // Delete return
  Future<void> deleteReturn(String id) async {
    try {
      // Get the return to check if we need to update customer balance
      final returnModel = await getReturnById(id);

      await _fsService.deleteReturn(id);

      // If it's an unapplied (or partially applied) sales return, remove only the
      // remaining credit from the customer's pendingReturnAmount. amountApplied has
      // already been deducted from pendingReturnAmount by earlier applyAllReturnsBatch
      // calls, so removing refundAmount here would over-subtract.
      if (returnModel != null &&
          returnModel.returnType == 'sales' &&
          returnModel.customerId != null &&
          !returnModel.isApplied) {
        final remainingCredit = returnModel.refundAmount - returnModel.amountApplied;
        if (remainingCredit > 0) {
          await _customerService.removePendingReturn(
            returnModel.customerId!,
            remainingCredit,
          );
        }
      }

      AppLogger.info('Return deleted successfully: $id', 'ReturnService');
    } catch (e) {
      AppLogger.error('Failed to delete return', 'ReturnService', e);
      rethrow;
    }
  }

  // Get pending (unapplied) returns for a customer
  Future<List<ReturnModel>> getPendingReturnsByCustomerId(String customerId) async {
    try {
      final allReturns = await getReturnsByCustomerId(customerId);
      return allReturns.where((r) => !r.isApplied && r.returnType == 'sales').toList();
    } catch (e) {
      AppLogger.error('Failed to get pending returns', 'ReturnService', e);
      return [];
    }
  }

  // Get total pending return amount for a customer
  Future<double> getTotalPendingReturnAmount(String customerId) async {
    try {
      final pendingReturns = await getPendingReturnsByCustomerId(customerId);
      return pendingReturns.fold<double>(0.0, (sum, r) => sum + (r.refundAmount - r.amountApplied));
    } catch (e) {
      AppLogger.error('Failed to get total pending return amount', 'ReturnService', e);
      return 0.0;
    }
  }

  // Apply pending returns to an invoice amount.
  //
  // Same-device guard: _applyInProgress blocks a second concurrent call on this
  // device (double-tap / slow connection). Returns invoiceAmount unchanged if
  // already in flight; resets on success or failure so the user can retry.
  //
  // Two-device safety: reads and writes execute inside a Firestore Transaction
  // (applyAllReturnsTransaction). If a concurrent device commits a write to any
  // locked return or the customer document before this transaction commits, the
  // SDK aborts and retries automatically with fresh data — double-spend is impossible.
  //
  // Throws on transaction failure so the caller knows no reduction occurred.
  Future<double> applyPendingReturnsToInvoice(String customerId, double invoiceAmount) async {
    if (_applyInProgress) {
      AppLogger.warning('Return application already in progress — skipped', 'ReturnService');
      return invoiceAmount;
    }
    _applyInProgress = true;
    try {
      return await _fsService.applyAllReturnsTransaction(
        customerId,
        invoiceAmount,
        (liveReturns, liveCustomer) {
          // Filter to unapplied sales returns only — all customer returns are locked
          // by the transaction but only these are eligible for application.
          final pending = liveReturns
              .where((r) => !r.isApplied && r.returnType == 'sales')
              .toList();

          if (pending.isEmpty) return ([], liveCustomer, invoiceAmount);

          double remainingAmount = invoiceAmount;
          double runningPendingAmount = liveCustomer.pendingReturnAmount;
          final List<ReturnModel> updatedReturns = [];

          for (final returnModel in pending) {
            if (remainingAmount <= 0) break;

            // Use remaining credit, not original refundAmount, to avoid
            // over-crediting a partially-applied return on subsequent invoices.
            final remainingCredit = returnModel.refundAmount - returnModel.amountApplied;
            if (remainingCredit <= 0) continue;

            final amountToApply = remainingAmount >= remainingCredit ? remainingCredit : remainingAmount;
            remainingAmount -= amountToApply;
            runningPendingAmount = (runningPendingAmount - amountToApply).clamp(0.0, double.infinity);

            final newAmountApplied = returnModel.amountApplied + amountToApply;
            final fullyApplied = newAmountApplied >= returnModel.refundAmount - 0.001;

            updatedReturns.add(returnModel.copyWith(
              amountApplied: newAmountApplied,
              isApplied: fullyApplied,
              updatedAt: DateTime.now(),
            ));
          }

          if (updatedReturns.isEmpty) return ([], liveCustomer, invoiceAmount);

          final updatedCustomer = liveCustomer.copyWith(
            pendingReturnAmount: runningPendingAmount,
            updatedAt: DateTime.now(),
          );

          return (updatedReturns, updatedCustomer, remainingAmount >= 0 ? remainingAmount : 0.0);
        },
      );
    } finally {
      _applyInProgress = false;
    }
  }
}
