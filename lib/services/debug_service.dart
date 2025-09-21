import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class DebugService {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Debug method to check what's actually in Firestore
  static Future<void> debugFirestoreInvoices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[DEBUG] No authenticated user');
        return;
      }

      print('[DEBUG] Checking Firestore for user: ${user.uid}');
      print('[DEBUG] User email: ${user.email}');

      // Direct Firestore query
      final invoicesRef = _fs.collection('users').doc(user.uid).collection('invoices');
      final snapshot = await invoicesRef.get();

      print('[DEBUG] Found ${snapshot.docs.length} invoices in Firestore');
      
      if (snapshot.docs.isEmpty) {
        print('[DEBUG] No invoices found in Firestore - checking if user document exists');
        
        // Check if user document exists
        final userDoc = await _fs.collection('users').doc(user.uid).get();
        print('[DEBUG] User document exists: ${userDoc.exists}');
        if (userDoc.exists) {
          print('[DEBUG] User document data: ${userDoc.data()}');
        }
      } else {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          print('[DEBUG] Invoice ID: ${doc.id}');
          print('[DEBUG] Invoice Type: ${data['invoiceType']}');
          print('[DEBUG] Invoice Number: ${data['invoiceNumber']}');
          print('[DEBUG] Client Name: ${data['clientName']}');
          print('[DEBUG] Status: ${data['status']}');
          print('[DEBUG] Revenue: ${data['revenue']}');
          print('[DEBUG] Created At: ${data['createdAt']}');
          print('[DEBUG] ---');
        }
      }

      // Also check using FirestoreService
      print('[DEBUG] Using FirestoreService.getAllInvoices():');
      final firestoreService = FirestoreService.instance;
      final invoicesFromService = await firestoreService.getAllInvoices();
      print('[DEBUG] Service returned ${invoicesFromService.length} invoices');
      
      for (final invoice in invoicesFromService) {
        print('[DEBUG] Service Invoice: ${invoice.id} - ${invoice.invoiceNumber} - ${invoice.clientName}');
      }
      
    } catch (e, stackTrace) {
      print('[DEBUG] Error checking Firestore: $e');
      print('[DEBUG] Stack trace: $stackTrace');
    }
  }

  /// Debug method to check authentication state
  static Future<void> debugAuthState() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[DEBUG AUTH] No user signed in');
      return;
    }

    print('[DEBUG AUTH] User ID: ${user.uid}');
    print('[DEBUG AUTH] Email: ${user.email}');
    print('[DEBUG AUTH] Email verified: ${user.emailVerified}');
    print('[DEBUG AUTH] Created: ${user.metadata.creationTime}');
    print('[DEBUG AUTH] Last sign in: ${user.metadata.lastSignInTime}');
  }

  /// Create a test invoice to verify storage
  static Future<void> createTestInvoice() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[DEBUG] Cannot create test invoice - no user signed in');
        return;
      }

      print('[DEBUG] Creating test invoice for user: ${user.uid}');
      
      final testInvoiceData = {
        'id': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        'invoiceNumber': 'TEST-001',
        'clientName': 'Test Client',
        'invoiceType': 'sales',
        'status': 'posted',
        'revenue': 100.0,
        'amountPaid': 100.0,
        'date': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'items': [
          {
            'name': 'Test Item',
            'quantity': 1,
            'price': 100.0,
          }
        ],
      };

      final docRef = _fs.collection('users').doc(user.uid).collection('invoices').doc(testInvoiceData['id'] as String);
      await docRef.set(testInvoiceData);
      
      print('[DEBUG] Test invoice created successfully');
      
      // Verify it was created
      final createdDoc = await docRef.get();
      print('[DEBUG] Test invoice verification - exists: ${createdDoc.exists}');
      if (createdDoc.exists) {
        final data = createdDoc.data();
        print('[DEBUG] Test invoice data: ${data?['invoiceNumber']} - ${data?['clientName']}');
      }
      
    } catch (e, stackTrace) {
      print('[DEBUG] Error creating test invoice: $e');
      print('[DEBUG] Stack trace: $stackTrace');
    }
  }
}
