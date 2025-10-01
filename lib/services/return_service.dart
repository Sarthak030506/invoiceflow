import '../models/return_model.dart';
import './firestore_service.dart';
import './customer_service.dart';
import '../utils/app_logger.dart';

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

  // Generate unique return number
  Future<String> generateReturnNumber(String returnType) async {
    final prefix = returnType == 'sales' ? 'SR' : 'PR';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp';
  }

  // Create a new return
  Future<void> createReturn(ReturnModel returnModel) async {
    try {
      await _fsService.createReturn(returnModel);

      // If it's a sales return, update customer's pending return amount
      if (returnModel.returnType == 'sales' && returnModel.customerId != null) {
        await _customerService.addPendingReturn(
          returnModel.customerId!,
          returnModel.refundAmount,
        );
      }

      AppLogger.info('Return created successfully: ${returnModel.returnNumber}', 'ReturnService');
    } catch (e) {
      AppLogger.error('Failed to create return', 'ReturnService', e);
      rethrow;
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

      // If it's an unapplied sales return, remove from customer's pending return amount
      if (returnModel != null &&
          returnModel.returnType == 'sales' &&
          returnModel.customerId != null &&
          !returnModel.isApplied) {
        await _customerService.removePendingReturn(
          returnModel.customerId!,
          returnModel.refundAmount,
        );
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
      return pendingReturns.fold<double>(0.0, (sum, r) => sum + r.refundAmount);
    } catch (e) {
      AppLogger.error('Failed to get total pending return amount', 'ReturnService', e);
      return 0.0;
    }
  }

  // Apply pending returns to an invoice amount
  Future<double> applyPendingReturnsToInvoice(String customerId, double invoiceAmount) async {
    try {
      final pendingReturns = await getPendingReturnsByCustomerId(customerId);
      if (pendingReturns.isEmpty) {
        return invoiceAmount;
      }

      double remainingAmount = invoiceAmount;

      for (var returnModel in pendingReturns) {
        if (remainingAmount <= 0) break;

        final amountToApply = remainingAmount >= returnModel.refundAmount
            ? returnModel.refundAmount
            : remainingAmount;

        remainingAmount -= amountToApply;

        // Mark return as applied
        await markReturnAsApplied(returnModel.id);

        // Update customer's pending return amount
        await _customerService.removePendingReturn(
          customerId,
          amountToApply,
        );
      }

      return remainingAmount >= 0 ? remainingAmount : 0;
    } catch (e) {
      AppLogger.error('Failed to apply pending returns to invoice', 'ReturnService', e);
      return invoiceAmount;
    }
  }
}
