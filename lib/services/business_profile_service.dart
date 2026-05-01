import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business_profile_model.dart';
import '../utils/app_logger.dart';

class BusinessProfileService {
  BusinessProfileService._();
  static final BusinessProfileService instance = BusinessProfileService._();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool? _profileCompleteCache;
  DateTime? _profileCompleteCacheTime;

  String _requireUid() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _fs.collection('users').doc(uid).collection('settings').doc('business_profile');

  Future<BusinessProfileModel?> getProfile() async {
    try {
      final uid = _requireUid();
      final snap = await _profileDoc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return BusinessProfileModel.fromMap(snap.data()!);
    } catch (e) {
      AppLogger.error('Failed to load business profile', 'BusinessProfileService', e);
      return null;
    }
  }

  Future<void> saveProfile(BusinessProfileModel profile) async {
    final uid = _requireUid();
    await _profileDoc(uid).set(profile.toMap(), SetOptions(merge: true));
    AppLogger.info('Business profile saved', 'BusinessProfileService');
  }

  Future<bool> isProfileComplete() async {
    if (_profileCompleteCache != null &&
        _profileCompleteCacheTime != null &&
        DateTime.now().difference(_profileCompleteCacheTime!).inSeconds < 60) {
      return _profileCompleteCache!;
    }
    final profile = await getProfile();
    _profileCompleteCache = profile != null && profile.isComplete;
    _profileCompleteCacheTime = DateTime.now();
    return _profileCompleteCache!;
  }

  void invalidateProfileCache() {
    _profileCompleteCache = null;
    _profileCompleteCacheTime = null;
  }

  Future<void> markOnboardingComplete() async {
    final uid = _requireUid();
    await _profileDoc(uid).set(
      {'onboardingCompletedAt': Timestamp.now()},
      SetOptions(merge: true),
    );
    AppLogger.info('Onboarding marked complete', 'BusinessProfileService');
  }

  Future<bool> isOnboardingComplete() async {
    try {
      final uid = _requireUid();
      final snap = await _profileDoc(uid).get();
      if (!snap.exists) return false;
      final data = snap.data();
      return data != null && data['onboardingCompletedAt'] != null;
    } catch (e) {
      AppLogger.error(
          'Failed to check onboarding status', 'BusinessProfileService', e);
      return false;
    }
  }
}
