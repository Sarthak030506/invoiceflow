import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';
import 'package:invoiceflow/services/subscription_service.dart';
import 'package:invoiceflow/services/ai/fuzzy_matcher_service.dart';

/// OCR Service - Handles receipt scanning with Gemini Vision API and fuzzy matching
class OCRService {
  static final OCRService instance = OCRService._();
  OCRService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final FuzzyMatcherService _fuzzyMatcher = FuzzyMatcherService.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Scan receipt and extract invoice data with fuzzy matching
  Future<OCRScanModel> scanReceipt(
    File imageFile, {
    List<Map<String, dynamic>>? catalogItems,
  }) async {
    // 1. Check subscription limits
    final canAccess = await _subscriptionService.canAccessFeature('ocr');
    if (!canAccess) {
      throw OCRException(
        'OCR scans limit reached. Please upgrade to Premium for unlimited scans.',
      );
    }

    // 2. Validate image file
    if (!await imageFile.exists()) {
      throw OCRException('Image file not found');
    }

    final fileSizeInBytes = await imageFile.length();
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    if (fileSizeInBytes > maxSizeInBytes) {
      throw OCRException('Image file too large. Maximum size is 10MB.');
    }

    // 3. Upload image to Firebase Storage
    final imageUrl = await _uploadImage(imageFile);

    // 4. Create initial scan record
    final scanId = _generateScanId();
    final scan = OCRScanModel(
      id: scanId,
      scanDate: DateTime.now(),
      imageUrl: imageUrl,
      status: ScanStatus.processing,
      createdAt: DateTime.now(),
    );

    await _saveScan(scan);

    try {
      // 5. Call Firebase Function for Gemini OCR processing
      final extractedData = await _callOCRFunction(imageUrl, scanId);

      // 6. Perform fuzzy matching on extracted items
      final matchedItems = await _matchExtractedItems(
        extractedData['items'] as List<dynamic>,
        catalogItems,
      );

      // 7. Update scan with results
      final completedScan = scan.copyWith(
        extractedData: ExtractedData(
          items: matchedItems,
          totalAmount: extractedData['totalAmount']?.toDouble(),
          vendor: extractedData['vendor'],
          date: extractedData['date'] != null
              ? DateTime.tryParse(extractedData['date'].toString())
              : null,
        ),
        status: ScanStatus.completed,
      );

      await _updateScan(completedScan);

      // 8. Decrement usage counter
      await _subscriptionService.decrementOCRScans();

      // 9. Track usage
      await _subscriptionService.trackFeatureUsage('ocr', {
        'scanId': scanId,
        'itemsDetected': matchedItems.length,
        'avgConfidence': matchedItems.isEmpty
            ? 0.0
            : matchedItems.map((i) => i.confidence).reduce((a, b) => a + b) /
                matchedItems.length,
      });

      return completedScan;
    } catch (e) {
      // Update scan with error
      final failedScan = scan.copyWith(
        status: ScanStatus.failed,
        errorMessage: e.toString(),
      );
      await _updateScan(failedScan);
      rethrow;
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    if (_currentUserId == null) {
      throw OCRException('User not authenticated');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ocr_scans/$_currentUserId/$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      // Upload with metadata
      await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': _currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw OCRException('Failed to upload image: $e');
    }
  }

  /// Call Firebase Function to process OCR with Gemini Vision API.
  /// Uses httpsCallable so the SDK auto-attaches Auth + App Check tokens.
  Future<Map<String, dynamic>> _callOCRFunction(
    String imageUrl,
    String scanId,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'processOCR',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({
        'imageUrl': imageUrl,
        'scanId': scanId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw OCRException('OCR processing failed: ${data['error'] ?? 'Unknown error'}');
      }
      return Map<String, dynamic>.from(data['data'] as Map);
    } on FirebaseFunctionsException catch (e) {
      throw OCRException('OCR processing failed: ${e.message}');
    } catch (e) {
      if (e is OCRException) rethrow;
      throw OCRException('Failed to call OCR function: $e');
    }
  }

  /// Match extracted items with catalog using fuzzy matching
  Future<List<ExtractedItem>> _matchExtractedItems(
    List<dynamic> rawItems,
    List<Map<String, dynamic>>? catalogItems,
  ) async {
    if (catalogItems == null || catalogItems.isEmpty) {
      // Return items without matches if no catalog provided
      return rawItems.map((item) {
        return ExtractedItem(
          rawText: item['text']?.toString() ?? '',
          confidence: 0.0,
          quantity: item['quantity']?.toInt(),
          price: item['price']?.toDouble(),
        );
      }).toList();
    }

    List<ExtractedItem> matched = [];

    for (var rawItem in rawItems) {
      final rawText = rawItem['text']?.toString() ?? '';

      if (rawText.isEmpty) continue;

      // Find best matches using fuzzy matcher
      final matches = await _fuzzyMatcher.findBestMatches(
        rawText,
        catalogItems,
        maxResults: 1,
        minConfidence: 0.5,
      );

      matched.add(ExtractedItem(
        rawText: rawText,
        matchedItemId: matches.isNotEmpty ? matches.first.itemId : null,
        matchedItemName: matches.isNotEmpty ? matches.first.itemName : null,
        confidence: matches.isNotEmpty ? matches.first.confidence : 0.0,
        quantity: rawItem['quantity']?.toInt(),
        price: rawItem['price']?.toDouble(),
      ));
    }

    return matched;
  }

  /// Save scan to Firestore
  Future<void> _saveScan(OCRScanModel scan) async {
    if (_currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('ocr_scans')
        .doc(scan.id)
        .set(scan.toFirestore());
  }

  /// Update scan in Firestore
  Future<void> _updateScan(OCRScanModel scan) async {
    if (_currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('ocr_scans')
        .doc(scan.id)
        .update(scan.toFirestore());
  }

  /// Get scan by ID
  Future<OCRScanModel?> getScanById(String scanId) async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('ocr_scans')
          .doc(scanId)
          .get();

      if (!doc.exists) return null;

      return OCRScanModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get all scans for current user
  Future<List<OCRScanModel>> getAllScans({int limit = 50}) async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('ocr_scans')
          .orderBy('scanDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => OCRScanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete scan
  Future<void> deleteScan(String scanId) async {
    if (_currentUserId == null) return;

    try {
      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('ocr_scans')
          .doc(scanId)
          .delete();

      // TODO: Also delete image from Storage if needed
    } catch (e) {
      throw OCRException('Failed to delete scan: $e');
    }
  }

  /// Generate unique scan ID
  String _generateScanId() {
    return 'OCR_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Link scan to invoice (called after invoice is created from scan)
  Future<void> linkScanToInvoice(String scanId, String invoiceId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('ocr_scans')
          .doc(scanId)
          .update({'invoiceId': invoiceId});
    } catch (e) {
      // Non-critical error, just log it
      print('Failed to link scan to invoice: $e');
    }
  }
}
