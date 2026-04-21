import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfileModel {
  final String shopName;
  final String ownerPhone;
  final String address;
  final String? gstin;
  final String? businessType;
  final DateTime? onboardingCompletedAt;

  const BusinessProfileModel({
    required this.shopName,
    required this.ownerPhone,
    required this.address,
    this.gstin,
    this.businessType,
    this.onboardingCompletedAt,
  });

  bool get isComplete =>
      shopName.trim().isNotEmpty &&
      ownerPhone.trim().isNotEmpty &&
      address.trim().isNotEmpty;

  bool get isGstRegistered => gstin != null && gstin!.trim().isNotEmpty;

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'ownerPhone': ownerPhone,
        'address': address,
        'gstin': gstin,
        'businessType': businessType,
        if (onboardingCompletedAt != null)
          'onboardingCompletedAt': Timestamp.fromDate(onboardingCompletedAt!),
      };

  factory BusinessProfileModel.fromMap(Map<String, dynamic> map) =>
      BusinessProfileModel(
        shopName: map['shopName'] as String? ?? '',
        ownerPhone: map['ownerPhone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        gstin: map['gstin'] as String?,
        businessType: map['businessType'] as String?,
        onboardingCompletedAt:
            (map['onboardingCompletedAt'] as Timestamp?)?.toDate(),
      );

  BusinessProfileModel copyWith({
    String? shopName,
    String? ownerPhone,
    String? address,
    String? gstin,
    String? businessType,
    DateTime? onboardingCompletedAt,
  }) =>
      BusinessProfileModel(
        shopName: shopName ?? this.shopName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        address: address ?? this.address,
        gstin: gstin ?? this.gstin,
        businessType: businessType ?? this.businessType,
        onboardingCompletedAt:
            onboardingCompletedAt ?? this.onboardingCompletedAt,
      );
}
