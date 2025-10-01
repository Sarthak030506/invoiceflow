import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/return_model.dart';
import '../models/catalog_item.dart';
import '../utils/app_logger.dart';

/// FirestoreService provides CRUD operations and a one-time migration from the
/// existing local SQLite database (DatabaseService) to Cloud Firestore.
///
/// Data model in Firestore (multi-tenant per authenticated user):
/// - users/{uid}/customers/{customerId}
/// - users/{uid}/invoices/{invoiceId}
///   (items stored inline as an array on the invoice document)
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ensure we have a signed-in user and return their UID.
  String _requireUid() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user. Sign in before using FirestoreService.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _customersCol(String uid) =>
      _fs.collection('users').doc(uid).collection('customers');

  CollectionReference<Map<String, dynamic>> _invoicesCol(String uid) =>
      _fs.collection('users').doc(uid).collection('invoices');

  CollectionReference<Map<String, dynamic>> _returnsCol(String uid) =>
      _fs.collection('users').doc(uid).collection('returns');

  CollectionReference<Map<String, dynamic>> _catalogRatesCol(String uid) =>
      _fs.collection('users').doc(uid).collection('catalog_rates');

  // ----------------------
  // Customer operations
  // ----------------------
  Future<void> upsertCustomer(CustomerModel customer) async {
    final uid = _requireUid();
    final doc = _customersCol(uid).doc(customer.id);
    await doc.set(_customerToFirestore(customer), SetOptions(merge: true));
  }

  Future<CustomerModel?> getCustomer(String customerId) async {
    final uid = _requireUid();
    final snap = await _customersCol(uid).doc(customerId).get();
    if (!snap.exists) return null;
    return _customerFromFirestore(snap.data()!..['id'] = snap.id);
  }

  // Convenience alias to match existing call sites
  Future<CustomerModel?> getCustomerById(String customerId) => getCustomer(customerId);

  // Lookup customer by phone number
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async {
    final uid = _requireUid();
    final q = await _customersCol(uid)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return _customerFromFirestore(d.data()..['id'] = d.id);
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final uid = _requireUid();
    final q = await _customersCol(uid).orderBy('name').get();
    return q.docs
        .map((d) => _customerFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<void> deleteCustomer(String customerId) async {
    final uid = _requireUid();
    await _customersCol(uid).doc(customerId).delete();
  }

  // ----------------------
  // Invoice operations
  // ----------------------
  Future<void> upsertInvoice(InvoiceModel invoice) async {
    final uid = _requireUid();
    final doc = _invoicesCol(uid).doc(invoice.id);
    try {
      await doc.set(_invoiceToFirestore(invoice), SetOptions(merge: true));
      AppLogger.firebase('upsertInvoice', 'success', invoice.id);
    } catch (e) {
      AppLogger.error('Firestore upsertInvoice failed', 'Firestore', e);
      rethrow;
    }
  }

  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    final uid = _requireUid();
    final snap = await _invoicesCol(uid).doc(invoiceId).get();
    if (!snap.exists) return null;
    return _invoiceFromFirestore(snap.data()!..['id'] = snap.id);
  }

  // Convenience alias to match existing call sites
  Future<InvoiceModel?> getInvoiceById(String invoiceId) => getInvoice(invoiceId);

  /// Check if an invoice number already exists for the current user
  Future<bool> isInvoiceNumberExists(String invoiceNumber) async {
    final uid = _requireUid();
    final q = await _invoicesCol(uid)
        .where('invoiceNumber', isEqualTo: invoiceNumber)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  /// Generate next sequential invoice number for the current user
  Future<String> generateNextInvoiceNumber() async {
    final uid = _requireUid();
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}';

    // Query for invoices with the current month prefix
    final q = await _invoicesCol(uid)
        .where('invoiceNumber', isGreaterThanOrEqualTo: 'INV-$datePrefix')
        .where('invoiceNumber', isLessThan: 'INV-$datePrefix\uf8ff')
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();

    int nextSequence = 1;
    if (q.docs.isNotEmpty) {
      final lastInvoiceNumber = q.docs.first.data()['invoiceNumber'] as String;
      final sequencePart = lastInvoiceNumber.split('-').last;
      if (sequencePart.length >= 6 && sequencePart.startsWith(datePrefix)) {
        final currentSequence = int.tryParse(sequencePart.substring(6)) ?? 0;
        nextSequence = currentSequence + 1;
      }
    }

    return 'INV-$datePrefix${nextSequence.toString().padLeft(3, '0')}';
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final uid = _requireUid();
    final q = await _invoicesCol(uid).orderBy('date', descending: true).get();
    return q.docs
        .map((d) => _invoiceFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<List<InvoiceModel>> getRecentInvoices({int limit = 5}) async {
    final uid = _requireUid();
    final q = await _invoicesCol(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return q.docs
        .map((d) => _invoiceFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<List<InvoiceModel>> getInvoicesByCustomerId(String customerId) async {
    final uid = _requireUid();
    final q = await _invoicesCol(uid)
        .where('customerId', isEqualTo: customerId)
        .get();
    final invoices = q.docs
        .map((d) => _invoiceFromFirestore(d.data()..['id'] = d.id))
        .toList();
    // Sort in memory to avoid index requirement
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final uid = _requireUid();
    await _invoicesCol(uid).doc(invoiceId).delete();
  }

  /// Deletes all invoices for the current user. Use with caution.
  Future<void> deleteAllInvoices() async {
    final uid = _requireUid();
    final q = await _invoicesCol(uid).get();
    WriteBatch batch = _fs.batch();
    int count = 0;
    for (final d in q.docs) {
      batch.delete(d.reference);
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _fs.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Future<Map<String, double>> getCustomerOutstandingBalances() async {
    // Safer query: limit to sales invoices; filter null/empty customerId and cancelled locally
    final uid = _requireUid();
    final q = await _invoicesCol(uid)
        .where('invoiceType', isEqualTo: 'sales')
        .get();
    final balances = <String, double>{};
    for (final d in q.docs) {
      final data = d.data();
      final String? customerId = data['customerId'] as String?;
      final String status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
      if (customerId == null || customerId.isEmpty) continue;
      if (status == 'cancelled') continue;
      final total = (data['revenue'] as num?)?.toDouble() ?? 0.0;
      final paid = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
      final remaining = total - paid;
      if (remaining > 0) {
        balances[customerId] = (balances[customerId] ?? 0.0) + remaining;
      }
    }
    return balances;
  }

  /// Explicitly clear fields on an invoice document by deleting them.
  Future<void> clearInvoiceFields(String invoiceId, List<String> fieldNames) async {
    final uid = _requireUid();
    final ref = _invoicesCol(uid).doc(invoiceId);
    final payload = <String, Object?>{};
    for (final f in fieldNames) {
      payload[f] = FieldValue.delete();
    }
    try {
      await ref.update(payload);
      AppLogger.firebase('clearInvoiceFields', 'success', invoiceId);
    } catch (e) {
      AppLogger.error('Firestore clearInvoiceFields failed', 'Firestore', e);
      rethrow;
    }
  }

  // ----------------------
  // Return operations
  // ----------------------
  Future<void> createReturn(ReturnModel returnModel) async {
    final uid = _requireUid();
    final doc = _returnsCol(uid).doc(returnModel.id);
    await doc.set(_returnToFirestore(returnModel));
    AppLogger.firebase('createReturn', 'success', returnModel.id);
  }

  Future<ReturnModel?> getReturnById(String returnId) async {
    final uid = _requireUid();
    final snap = await _returnsCol(uid).doc(returnId).get();
    if (!snap.exists) return null;
    return _returnFromFirestore(snap.data()!..['id'] = snap.id);
  }

  Future<List<ReturnModel>> getReturns() async {
    final uid = _requireUid();
    final q = await _returnsCol(uid).orderBy('returnDate', descending: true).get();
    return q.docs
        .map((d) => _returnFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<List<ReturnModel>> getReturnsByType(String returnType) async {
    final uid = _requireUid();
    final q = await _returnsCol(uid)
        .where('returnType', isEqualTo: returnType)
        .orderBy('returnDate', descending: true)
        .get();
    return q.docs
        .map((d) => _returnFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<List<ReturnModel>> getReturnsByCustomerId(String customerId) async {
    final uid = _requireUid();
    final q = await _returnsCol(uid)
        .where('customerId', isEqualTo: customerId)
        .orderBy('returnDate', descending: true)
        .get();
    return q.docs
        .map((d) => _returnFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<List<ReturnModel>> getReturnsByInvoiceId(String invoiceId) async {
    final uid = _requireUid();
    final q = await _returnsCol(uid)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('returnDate', descending: true)
        .get();
    return q.docs
        .map((d) => _returnFromFirestore(d.data()..['id'] = d.id))
        .toList();
  }

  Future<void> updateReturn(ReturnModel returnModel) async {
    final uid = _requireUid();
    final doc = _returnsCol(uid).doc(returnModel.id);
    await doc.set(_returnToFirestore(returnModel), SetOptions(merge: true));
    AppLogger.firebase('updateReturn', 'success', returnModel.id);
  }

  Future<void> deleteReturn(String returnId) async {
    final uid = _requireUid();
    await _returnsCol(uid).doc(returnId).delete();
  }

  // ----------------------
  // Catalog rate operations
  // ----------------------
  Future<void> updateCatalogItemRate(CatalogItem item) async {
    final uid = _requireUid();
    final doc = _catalogRatesCol(uid).doc(item.id.toString());
    await doc.set({
      'id': item.id,
      'name': item.name,
      'rate': item.rate,
      'updatedAt': Timestamp.now(),
    });
    AppLogger.firebase('updateCatalogItemRate', 'success', item.id.toString());
  }

  Future<List<CatalogItem>> getAllCatalogRates() async {
    final uid = _requireUid();
    final q = await _catalogRatesCol(uid).get();
    return q.docs.map((d) {
      final data = d.data();
      return CatalogItem(
        id: data['id'] as int,
        name: data['name'] as String? ?? '',
        rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<void> deleteCatalogItemRate(int itemId) async {
    final uid = _requireUid();
    await _catalogRatesCol(uid).doc(itemId.toString()).delete();
  }

  // ----------------------
  // Helpers
  // ----------------------
  Map<String, dynamic> _customerToFirestore(CustomerModel c) {
    return {
      'name': c.name,
      'phoneNumber': c.phoneNumber,
      'pendingReturnAmount': c.pendingReturnAmount,
      // Store as Firestore Timestamp
      'createdAt': Timestamp.fromDate(c.createdAt),
      'updatedAt': Timestamp.fromDate(c.updatedAt),
    };
  }

  CustomerModel _customerFromFirestore(Map<String, dynamic> data) {
    return CustomerModel(
      id: data['id'] as String,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      pendingReturnAmount: (data['pendingReturnAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _invoiceToFirestore(InvoiceModel inv) {
    return {
      'invoiceNumber': inv.invoiceNumber,
      'clientName': inv.clientName,
      'customerPhone': inv.customerPhone,
      'customerId': inv.customerId,
      'date': Timestamp.fromDate(inv.date),
      'revenue': inv.revenue,
      'status': inv.status,
      'notes': inv.notes,
      'createdAt': Timestamp.fromDate(inv.createdAt),
      'updatedAt': Timestamp.fromDate(inv.updatedAt),
      'invoiceType': inv.invoiceType,
      'amountPaid': inv.amountPaid,
      'paymentMethod': inv.paymentMethod,
      'followUpDate': inv.followUpDate != null ? Timestamp.fromDate(inv.followUpDate!) : null,
      'isDeleted': inv.isDeleted,
      'cancelledAt': inv.cancelledAt != null ? Timestamp.fromDate(inv.cancelledAt!) : null,
      'cancelReason': inv.cancelReason,
      'modifiedFlag': inv.modifiedFlag,
      'modifiedReason': inv.modifiedReason,
      'modifiedAt': inv.modifiedAt != null ? Timestamp.fromDate(inv.modifiedAt!) : null,
      // Store items inline as array
      'items': inv.items
          .map((it) => {
                'name': it.name,
                'quantity': it.quantity,
                'price': it.price,
              })
          .toList(),
    }..removeWhere((key, value) => value == null);
  }

  InvoiceModel _invoiceFromFirestore(Map<String, dynamic> data) {
    final items = (data['items'] as List?)?.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return InvoiceItem(
            name: m['name'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toInt() ?? 1,
            price: (m['price'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList() ??
        [];

    return InvoiceModel(
      id: data['id'] as String,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String?,
      customerId: data['customerId'] as String?,
      date: _asDate(data['date']),
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      items: items,
      notes: data['notes'] as String?,
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
      invoiceType: data['invoiceType'] as String? ?? 'sales',
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash',
      followUpDate: data['followUpDate'] != null ? _asDate(data['followUpDate']) : null,
      isDeleted: data['isDeleted'] as bool? ?? false,
      cancelledAt: data['cancelledAt'] != null ? _asDate(data['cancelledAt']) : null,
      cancelReason: data['cancelReason'] as String?,
      modifiedFlag: data['modifiedFlag'] as bool? ?? false,
      modifiedReason: data['modifiedReason'] as String?,
      modifiedAt: data['modifiedAt'] != null ? _asDate(data['modifiedAt']) : null,
    );
  }

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> _returnToFirestore(ReturnModel ret) {
    return {
      'returnNumber': ret.returnNumber,
      'invoiceId': ret.invoiceId,
      'invoiceNumber': ret.invoiceNumber,
      'customerName': ret.customerName,
      'customerId': ret.customerId,
      'customerPhone': ret.customerPhone,
      'invoiceDate': Timestamp.fromDate(ret.invoiceDate),
      'returnDate': Timestamp.fromDate(ret.returnDate),
      'returnType': ret.returnType,
      'returnReason': ret.returnReason,
      'notes': ret.notes,
      'totalReturnValue': ret.totalReturnValue,
      'refundAmount': ret.refundAmount,
      'isApplied': ret.isApplied,
      'createdAt': Timestamp.fromDate(ret.createdAt),
      'updatedAt': Timestamp.fromDate(ret.updatedAt),
      'items': ret.items
          .map((it) => {
                'name': it.name,
                'quantity': it.quantity,
                'price': it.price,
                'totalValue': it.totalValue,
              })
          .toList(),
    }..removeWhere((key, value) => value == null);
  }

  ReturnModel _returnFromFirestore(Map<String, dynamic> data) {
    final items = (data['items'] as List?)?.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return ReturnItem(
            name: m['name'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toInt() ?? 1,
            price: (m['price'] as num?)?.toDouble() ?? 0.0,
            totalValue: (m['totalValue'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList() ??
        [];

    return ReturnModel(
      id: data['id'] as String,
      returnNumber: data['returnNumber'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerId: data['customerId'] as String?,
      customerPhone: data['customerPhone'] as String?,
      invoiceDate: _asDate(data['invoiceDate']),
      returnDate: _asDate(data['returnDate']),
      returnType: data['returnType'] as String? ?? 'sales',
      items: items,
      returnReason: data['returnReason'] as String? ?? '',
      notes: data['notes'] as String?,
      totalReturnValue: (data['totalReturnValue'] as num?)?.toDouble() ?? 0.0,
      refundAmount: (data['refundAmount'] as num?)?.toDouble() ?? 0.0,
      isApplied: data['isApplied'] as bool? ?? false,
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
    );
  }

  // Batch helper respecting 500 ops per batch limit
  Future<void> _writeInBatches(Iterable<_BatchOp> ops) async {
    const maxOps = 450; // leave headroom for safety
    var batch = _fs.batch();
    var count = 0;

    Future<void> commitBatch() async {
      if (count == 0) return;
      await batch.commit();
      batch = _fs.batch();
      count = 0;
    }

    for (final op in ops) {
      batch.set(op.ref, op.data, SetOptions(merge: true));
      count++;
      if (count >= maxOps) {
        await commitBatch();
      }
    }
    await commitBatch();
  }
}

class _BatchOp {
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
  _BatchOp({required this.ref, required this.data});
}
