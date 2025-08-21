import 'package:flutter/services.dart';

class HapticFeedbackUtil {
  // Trigger a simple vibration feedback
  static void trigger() {
    HapticFeedback.selectionClick();
  }

  // Trigger success vibration feedback (see ImpactFeedbackStyle)
  static void success() {
    HapticFeedback.lightImpact();
  }

  // Trigger error vibration feedback
  static void error() {
    HapticFeedback.mediumImpact();
  }

  // Trigger notification vibration feedback
  static void notification() {
    HapticFeedback.heavyImpact();
  }
}
