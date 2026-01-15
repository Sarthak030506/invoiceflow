import 'package:cloud_firestore/cloud_firestore.dart';

enum ScanStatus { processing, completed, failed }

class OCRScanModel {
  final String id;
  final DateTime scanDate;
  final String imageUrl;
  final ExtractedData? extractedData;
  final ScanStatus status;
  final String? invoiceId; // If converted to invoice
  final String? errorMessage;
  final DateTime createdAt;

  OCRScanModel({
    required this.id,
    required this.scanDate,
    required this.imageUrl,
    this.extractedData,
    required this.status,
    this.invoiceId,
    this.errorMessage,
    required this.createdAt,
  });

  factory OCRScanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OCRScanModel(
      id: doc.id,
      scanDate: (data['scanDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
      extractedData: data['extractedData'] != null
          ? ExtractedData.fromMap(data['extractedData'])
          : null,
      status: ScanStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ScanStatus.processing,
      ),
      invoiceId: data['invoiceId'],
      errorMessage: data['errorMessage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scanDate': Timestamp.fromDate(scanDate),
      'imageUrl': imageUrl,
      'extractedData': extractedData?.toMap(),
      'status': status.name,
      'invoiceId': invoiceId,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  OCRScanModel copyWith({
    String? id,
    DateTime? scanDate,
    String? imageUrl,
    ExtractedData? extractedData,
    ScanStatus? status,
    String? invoiceId,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return OCRScanModel(
      id: id ?? this.id,
      scanDate: scanDate ?? this.scanDate,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedData: extractedData ?? this.extractedData,
      status: status ?? this.status,
      invoiceId: invoiceId ?? this.invoiceId,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExtractedData {
  final List<ExtractedItem> items;
  final double? totalAmount;
  final String? vendor;
  final DateTime? date;

  ExtractedData({
    required this.items,
    this.totalAmount,
    this.vendor,
    this.date,
  });

  factory ExtractedData.fromMap(Map<String, dynamic> map) {
    return ExtractedData(
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ExtractedItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: map['totalAmount']?.toDouble(),
      vendor: map['vendor'],
      date: map['date'] != null
          ? (map['date'] is Timestamp
              ? (map['date'] as Timestamp).toDate()
              : DateTime.tryParse(map['date'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'vendor': vendor,
      'date': date != null ? Timestamp.fromDate(date!) : null,
    };
  }
}

class ExtractedItem {
  final String rawText; // OCR extracted text
  final String? matchedItemId; // Matched catalog item ID
  final String? matchedItemName; // Matched catalog item name
  final double confidence; // Match confidence (0.0 to 1.0)
  final int? quantity;
  final double? price;

  ExtractedItem({
    required this.rawText,
    this.matchedItemId,
    this.matchedItemName,
    required this.confidence,
    this.quantity,
    this.price,
  });

  bool get hasMatch => matchedItemId != null && matchedItemName != null;

  bool get isHighConfidence => confidence >= 0.9;

  bool get isMediumConfidence => confidence >= 0.7 && confidence < 0.9;

  bool get isLowConfidence => confidence < 0.7;

  factory ExtractedItem.fromMap(Map<String, dynamic> map) {
    return ExtractedItem(
      rawText: map['rawText'] ?? '',
      matchedItemId: map['matchedItemId'],
      matchedItemName: map['matchedItemName'],
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      quantity: map['quantity']?.toInt(),
      price: map['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rawText': rawText,
      'matchedItemId': matchedItemId,
      'matchedItemName': matchedItemName,
      'confidence': confidence,
      'quantity': quantity,
      'price': price,
    };
  }

  ExtractedItem copyWith({
    String? rawText,
    String? matchedItemId,
    String? matchedItemName,
    double? confidence,
    int? quantity,
    double? price,
  }) {
    return ExtractedItem(
      rawText: rawText ?? this.rawText,
      matchedItemId: matchedItemId ?? this.matchedItemId,
      matchedItemName: matchedItemName ?? this.matchedItemName,
      confidence: confidence ?? this.confidence,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

// Exception for OCR-related errors
class OCRException implements Exception {
  final String message;
  OCRException(this.message);

  @override
  String toString() => 'OCRException: $message';
}

// Exception for subscription-related errors
class SubscriptionException implements Exception {
  final String message;
  SubscriptionException(this.message);

  @override
  String toString() => 'SubscriptionException: $message';
}
