import 'business_profile_service.dart';

class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._internal();

  OnboardingService._internal();

  Future<bool> shouldShowItemsOnboarding() async {
    try {
      final complete = await BusinessProfileService.instance.isOnboardingComplete();
      return !complete;
    } catch (e) {
      print('[OnboardingService] Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> markItemsOnboardingComplete() async {
    await BusinessProfileService.instance.markOnboardingComplete();
  }

  Future<bool> isFirstTimeUser() async {
    return await shouldShowItemsOnboarding();
  }
}
