import 'package:flutter/material.dart';

/// Global navigator key — allows services (e.g. NotificationService) to push
/// routes without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
