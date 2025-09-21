import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_service.dart';

class OnboardingService {
  static const String _keyHasCompletedItemsOnboarding = 'has_completed_items_onboarding';
  static const String _keyIsFirstTimeUser = 'is_first_time_user';

  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._internal();

  OnboardingService._internal();

  /// Check if user needs items onboarding
  Future<bool> shouldShowItemsOnboarding() async {
    try {
      print('[OnboardingService] shouldShowItemsOnboarding called');
      final prefs = await SharedPreferences.getInstance();

      // Debug: Show all current preferences
      final allKeys = prefs.getKeys();
      print('[OnboardingService] All SharedPreferences keys: $allKeys');
      for (final key in allKeys) {
        final value = prefs.get(key);
        print('[OnboardingService] $key: $value');
      }

      // Already completed?
      final hasCompleted = prefs.getBool(_keyHasCompletedItemsOnboarding) ?? false;
      print('[OnboardingService] hasCompleted onboarding: $hasCompleted');
      if (hasCompleted) {
        print('[OnboardingService] Onboarding already completed');
        return false;
      }

      // First-time logic - if no key exists, treat as first time
      // if key exists and is true, also treat as first time
      final hasFirstTimeKey = prefs.containsKey(_keyIsFirstTimeUser);
      final firstTimeValue = prefs.getBool(_keyIsFirstTimeUser);
      
      print('[OnboardingService] hasFirstTimeKey: $hasFirstTimeKey, firstTimeValue: $firstTimeValue');
      
      // Show onboarding if:
      // 1. No key exists (brand new user)
      // 2. Key exists and is true (marked as first-time user)
      final shouldShowForFirstTime = !hasFirstTimeKey || (firstTimeValue == true);
      
      if (shouldShowForFirstTime) {
        print('[OnboardingService] First-time user → showing onboarding');
        return true;
      }

      // Returning user: check if inventory has items
      print('[OnboardingService] Checking inventory for returning user...');
      final inventoryService = InventoryService();
      final items = await inventoryService.getAllItems();
      final shouldShow = items.isEmpty;
      print('[OnboardingService] Returning user has ${items.length} items → show onboarding: $shouldShow');
      return shouldShow;
    } catch (e) {
      print('[OnboardingService] Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<void> markItemsOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCompletedItemsOnboarding, true);
      await prefs.setBool(_keyIsFirstTimeUser, false);
      print('[OnboardingService] Marked onboarding complete');
    } catch (e) {
      print('[OnboardingService] Error marking onboarding complete: $e');
    }
  }

  /// Reset (for testing)
  Future<void> resetOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasCompletedItemsOnboarding);
      await prefs.remove(_keyIsFirstTimeUser);
      print('[OnboardingService] Reset state');
    } catch (e) {
      print('[OnboardingService] Error resetting onboarding state: $e');
    }
  }

  /// Query only
  Future<bool> isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyIsFirstTimeUser)
          ? (prefs.getBool(_keyIsFirstTimeUser) ?? false)
          : true;
    } catch (e) {
      print('[OnboardingService] Error checking first-time: $e');
      return false;
    }
  }
}
