import 'package:flutter/material.dart';
import '../widgets/adaptive_scaffold.dart';

/// Centralized navigation configuration for InvoiceFlow app.
///
/// This class defines all main navigation items used across the app,
/// ensuring consistency between mobile bottom navigation and desktop
/// navigation rail.
class NavigationConfig {
  /// Main navigation items for the 5 primary app screens
  static const List<NavigationItem> mainNavigationItems = [
    NavigationItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: 'Invoices',
    ),
    NavigationItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Analytics',
    ),
    NavigationItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Customers',
    ),
    NavigationItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];
}
