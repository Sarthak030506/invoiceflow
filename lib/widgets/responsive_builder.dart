import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A builder widget that provides different layouts based on screen size
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile layout (required)
  final Widget Function(BuildContext) mobile;

  /// Builder for tablet layout (optional, falls back to mobile)
  final Widget Function(BuildContext)? tablet;

  /// Builder for desktop layout (optional, falls back to tablet or mobile)
  final Widget Function(BuildContext)? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveHelper.isDesktop(context)) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (ResponsiveHelper.isTablet(context)) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}

/// A widget that wraps content with maximum width constraint on larger screens
///
/// Useful for centering content and preventing it from stretching too wide
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveHelper.maxContentWidth(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? width),
        padding: padding ?? ResponsiveHelper.padding(context),
        child: child,
      ),
    );
  }
}

/// A responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// A widget that switches between two layouts based on a breakpoint
///
/// Simpler alternative to ResponsiveBuilder when you only need two layouts
class BreakpointSwitch extends StatelessWidget {
  final double breakpoint;
  final Widget Function(BuildContext) small;
  final Widget Function(BuildContext) large;

  const BreakpointSwitch({
    Key? key,
    required this.breakpoint,
    required this.small,
    required this.large,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return large(context);
        }
        return small(context);
      },
    );
  }
}
