import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

/// Helper class for responsive design utilities
///
/// Provides methods to check device type, get responsive values,
/// and adapt layouts based on screen size
class ResponsiveHelper {
  // Private constructor
  ResponsiveHelper._();

  /// Get screen width from context
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height from context
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return Breakpoints.isMobile(screenWidth(context));
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return Breakpoints.isTablet(screenWidth(context));
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return Breakpoints.isDesktop(screenWidth(context));
  }

  /// Check if device is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return Breakpoints.isLargeDesktop(screenWidth(context));
  }

  /// Get device type
  static String deviceType(BuildContext context) {
    return Breakpoints.getDeviceType(screenWidth(context));
  }

  /// Get value based on device type
  ///
  /// Returns mobile value for mobile, tablet value for tablet,
  /// and desktop value for desktop
  static T getValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = screenWidth(context);
    if (Breakpoints.isDesktop(width)) {
      return desktop ?? tablet ?? mobile;
    }
    if (Breakpoints.isTablet(width)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Get responsive font size
  ///
  /// Scales font size based on screen width while maintaining readability
  static double fontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (Breakpoints.isDesktop(width)) {
      return baseSize * 1.0; // Keep same size or slightly smaller on desktop
    }
    if (Breakpoints.isTablet(width)) {
      return baseSize * 1.1; // Slightly larger on tablets
    }
    return baseSize; // Base size on mobile
  }

  /// Get responsive padding
  ///
  /// Returns appropriate padding based on screen size
  static EdgeInsets padding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getValue(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.all(value);
  }

  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getValue(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getValue(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.symmetric(vertical: value);
  }

  /// Get maximum content width for centered layouts on desktop
  ///
  /// Prevents content from stretching too wide on large screens
  static double maxContentWidth(BuildContext context) {
    return getValue(
      context: context,
      mobile: double.infinity,
      tablet: 900.0,
      desktop: 1200.0,
    );
  }

  /// Get number of columns for grid layouts
  static int gridColumns(BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
  }) {
    return getValue(
      context: context,
      mobile: mobile ?? 1,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
    );
  }

  /// Get appropriate icon size
  static double iconSize(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    return getValue(
      context: context,
      mobile: mobile ?? 24.0,
      tablet: tablet ?? 28.0,
      desktop: desktop ?? 32.0,
    );
  }

  /// Check if side navigation should be used (desktop/tablet landscape)
  static bool shouldUseSideNavigation(BuildContext context) {
    return isDesktop(context) ||
           (isTablet(context) && MediaQuery.of(context).orientation == Orientation.landscape);
  }

  /// Check if bottom navigation should be used (mobile/tablet portrait)
  static bool shouldUseBottomNavigation(BuildContext context) {
    return !shouldUseSideNavigation(context);
  }
}
