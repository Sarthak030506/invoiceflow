/// Responsive breakpoints for the app
///
/// Usage: Check screen width to determine device type and adjust layout
class Breakpoints {
  // Private constructor to prevent instantiation
  Breakpoints._();

  /// Mobile devices: 0 - 599px
  static const double mobile = 600;

  /// Tablet devices: 600 - 1023px
  static const double tablet = 1024;

  /// Desktop devices: 1024px and above
  static const double desktop = 1024;

  /// Large desktop: 1440px and above
  static const double largeDesktop = 1440;

  /// Check if current width is mobile
  static bool isMobile(double width) => width < mobile;

  /// Check if current width is tablet
  static bool isTablet(double width) => width >= mobile && width < desktop;

  /// Check if current width is desktop
  static bool isDesktop(double width) => width >= desktop;

  /// Check if current width is large desktop
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  /// Get device type as string
  static String getDeviceType(double width) {
    if (width < mobile) return 'mobile';
    if (width < desktop) return 'tablet';
    return 'desktop';
  }
}
