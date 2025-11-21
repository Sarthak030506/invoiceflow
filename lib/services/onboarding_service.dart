import 'items_service.dart';

class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._internal();

  OnboardingService._internal();

  final ItemsService _itemsService = ItemsService();

  /// Check if user needs items onboarding
  /// User needs onboarding if they have NO catalogue items
  Future<bool> shouldShowItemsOnboarding() async {
    try {
      print('[OnboardingService] shouldShowItemsOnboarding called');

      // Check if user has any catalogue items
      final itemsCount = await _itemsService.getItemsCount();
      final shouldShow = itemsCount == 0;

      print('[OnboardingService] Catalogue has $itemsCount items → show onboarding: $shouldShow');
      return shouldShow;
    } catch (e) {
      print('[OnboardingService] Error checking onboarding status: $e');
      // On error, don't show onboarding to avoid blocking user
      return false;
    }
  }

  /// Mark onboarding as complete
  /// Note: Completion is implicit - when user adds catalogue items,
  /// onboarding will no longer show automatically
  Future<void> markItemsOnboardingComplete() async {
    print('[OnboardingService] Onboarding completion tracked via catalogue items');
  }

  /// Check if user is first time (has no catalogue items)
  Future<bool> isFirstTimeUser() async {
    return await shouldShowItemsOnboarding();
  }
}
