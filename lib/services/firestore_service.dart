import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';

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
      // Debug logging for visibility issues
      print('[Firestore] upsertInvoice -> uid=$uid path=users/$uid/invoices/${invoice.id} type=${invoice.invoiceType} status=${invoice.status} amountPaid=${invoice.amountPaid}');
      await doc.set(_invoiceToFirestore(invoice), SetOptions(merge: true));
      print('[Firestore] upsertInvoice OK -> ${invoice.id}');
    } catch (e) {
      print('[Firestore] upsertInvoice ERROR uid=$uid id=${invoice.id}: $e');
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
        .orderBy('date', descending: true)
        .get();
    return q.docs
        .map((d) => _invoiceFromFirestore(d.data()..['id'] = d.id))
        .toList();
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
      print('[Firestore] clearInvoiceFields -> uid=$uid id=$invoiceId fields=${fieldNames.join(',')}');
      await ref.update(payload);
      print('[Firestore] clearInvoiceFields OK -> $invoiceId');
    } catch (e) {
      print('[Firestore] clearInvoiceFields ERROR id=$invoiceId: $e');
      rethrow;
    }
  }


  // ----------------------
  // Helpers
  // ----------------------
  Map<String, dynamic> _customerToFirestore(CustomerModel c) {
    return {
      'name': c.name,
      'phoneNumber': c.phoneNumber,
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
