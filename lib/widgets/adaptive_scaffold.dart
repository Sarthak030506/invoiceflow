import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// An adaptive scaffold that switches between bottom navigation (mobile)
/// and side navigation (tablet/desktop) based on screen size
///
/// This widget wraps the existing HomeDashboard navigation without breaking
/// mobile functionality while adding desktop support
class AdaptiveScaffold extends StatelessWidget {
  /// The body content to display
  final Widget body;

  /// Current selected navigation index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onNavigationChanged;

  /// Navigation items with icons and labels
  final List<NavigationItem> items;

  /// Optional app bar to show on top
  final PreferredSizeWidget? appBar;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional drawer for mobile
  final Widget? drawer;

  /// Optional background color
  final Color? backgroundColor;

  const AdaptiveScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.items,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On mobile: use existing bottom navigation
    if (ResponsiveHelper.shouldUseBottomNavigation(context)) {
      return Scaffold(
        appBar: appBar,
        drawer: drawer,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onNavigationChanged,
          items: items
              .map((item) => BottomNavigationBarItem(
                    icon: item.icon,
                    label: item.label,
                    activeIcon: item.activeIcon,
                  ))
              .toList(),
        ),
        backgroundColor: backgroundColor,
      );
    }

    // On desktop/tablet: use side navigation rail
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavigationChanged,
            labelType: NavigationRailLabelType.all,
            leading: drawer != null
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: 'Menu',
                    ),
                  )
                : null,
            trailing: floatingActionButton != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: floatingActionButton,
                  )
                : null,
            destinations: items
                .map((item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.activeIcon ?? item.icon,
                      label: Text(item.label),
                    ))
                .toList(),
          ),

          // Vertical divider
          const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: body,
          ),
        ],
      ),
      drawer: drawer,
      backgroundColor: backgroundColor,
    );
  }
}

/// Navigation item model for AdaptiveScaffold
class NavigationItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
