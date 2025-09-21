import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html';

/// Checks if the current platform is a desktop platform
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

/// Checks if the current platform is a mobile platform
bool get isMobile {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Checks if the current platform is web
bool get isWeb => kIsWeb;
