import 'package:flutter/foundation.dart';

/// Production-safe logging utility for InvoiceFlow
/// Replaces print() statements with proper logging that can be controlled
class AppLogger {
  static const String _appName = 'InvoiceFlow';

  /// Log levels
  static const String _info = 'INFO';
  static const String _warning = 'WARNING';
  static const String _error = 'ERROR';
  static const String _debug = 'DEBUG';

  /// Private constructor to prevent instantiation
  AppLogger._();

  /// Log info message (visible in debug and release)
  static void info(String message, [String? tag]) {
    _log(_info, message, tag);
  }

  /// Log warning message (visible in debug and release)
  static void warning(String message, [String? tag]) {
    _log(_warning, message, tag);
  }

  /// Log error message (visible in debug and release)
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(_error, message, tag);
    if (error != null && kDebugMode) {
      debugPrint('[$_appName] ERROR Details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('[$_appName] Stack Trace: $stackTrace');
    }
  }

  /// Log debug message (only visible in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      _log(_debug, message, tag);
    }
  }

  /// Internal logging method
  static void _log(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';

    // Only log in debug mode to prevent sensitive info leakage
    if (kDebugMode) {
      debugPrint('[$_appName] [$level] $timestamp $tagStr$message');
    }

    // In release mode, you could send critical logs to a logging service
    // if (kReleaseMode && (level == _error || level == _warning)) {
    //   _sendToLoggingService(level, message, tag);
    // }
  }

  /// Send logs to external logging service (implement as needed)
  // static void _sendToLoggingService(String level, String message, String? tag) {
  //   // Implement Firebase Crashlytics, Sentry, or other logging service
  //   // Example: FirebaseCrashlytics.instance.log('$level: $message');
  // }

  /// Log Firebase operation
  static void firebase(String operation, String result, [String? details]) {
    debug('Firebase $operation: $result${details != null ? ' - $details' : ''}', 'Firebase');
  }

  /// Log user action
  static void userAction(String action, [Map<String, dynamic>? params]) {
    final paramsStr = params?.toString() ?? '';
    info('User Action: $action $paramsStr', 'UserAction');
  }

  /// Log business operation
  static void business(String operation, String result, [String? entityId]) {
    final idStr = entityId != null ? ' (ID: $entityId)' : '';
    info('Business: $operation - $result$idStr', 'Business');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration, [String? details]) {
    final detailsStr = details != null ? ' - $details' : '';
    debug('Performance: $operation took ${duration.inMilliseconds}ms$detailsStr', 'Performance');
  }
}