import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Fluid animation utilities for smooth transitions and interactions
class FluidAnimations {
  FluidAnimations._();

  // Animation Durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve easeInOutCurve = Curves.easeInOut;
  static const Curve easeOutCurve = Curves.easeOut;
  static const Curve easeInCurve = Curves.easeIn;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;

  /// Create a fade transition page route
  static PageRouteBuilder<T> createFadeRoute<T>({
    required Widget child,
    RouteSettings? settings,
    Duration duration = mediumDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: easeOutCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Create a slide-up transition page route (modal style)
  static PageRouteBuilder<T> createSlideUpRoute<T>({
    required Widget child,
    RouteSettings? settings,
    Duration duration = mediumDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Create a Cupertino-style slide transition
  static PageRouteBuilder<T> createCupertinoSlideRoute<T>({
    required Widget child,
    RouteSettings? settings,
    Duration duration = mediumDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Create a scale transition page route
  static PageRouteBuilder<T> createScaleRoute<T>({
    required Widget child,
    RouteSettings? settings,
    Duration duration = mediumDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: easeOutCurve,
        ));

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: easeOutCurve,
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Create a rotation transition page route
  static PageRouteBuilder<T> createRotationRoute<T>({
    required Widget child,
    RouteSettings? settings,
    Duration duration = slowDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: elasticCurve,
          )),
          child: child,
        );
      },
    );
  }

  /// Create an animated container with smooth transitions
  static Widget createAnimatedContainer({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = easeInOutCurve,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    double? width,
    double? height,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      width: width,
      height: height,
      child: child,
    );
  }

  /// Create a hero widget for smooth transitions between screens
  static Widget createHero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }

  /// Create a staggered list animation
  static Widget createStaggeredListAnimation({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 50),
    Duration duration = mediumDuration,
    Curve curve = easeOutCurve,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + (delay * index),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Create an animated switcher with smooth transitions
  static Widget createAnimatedSwitcher({
    required Widget child,
    Duration duration = mediumDuration,
    Curve curve = easeInOutCurve,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      child: child,
    );
  }

  /// Create tap feedback animation for buttons
  static Widget createTapFeedback({
    required Widget child,
    required VoidCallback onTap,
    Duration duration = fastDuration,
    double scaleValue = 0.95,
    BorderRadius? borderRadius,
  }) {
    return TapFeedbackWidget(
      onTap: onTap,
      duration: duration,
      scaleValue: scaleValue,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Create a shimmer loading animation
  static Widget createShimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ShimmerWidget(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      duration: duration,
      child: child,
    );
  }

  /// Create a bounce animation
  static Widget createBounceAnimation({
    required Widget child,
    Duration duration = mediumDuration,
  }) {
    return BounceAnimationWidget(
      duration: duration,
      child: child,
    );
  }

  /// Create a pulse animation
  static Widget createPulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return PulseAnimationWidget(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }
}

/// Custom tap feedback widget with scale animation
class TapFeedbackWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double scaleValue;
  final BorderRadius? borderRadius;

  const TapFeedbackWidget({
    Key? key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 200),
    this.scaleValue = 0.95,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<TapFeedbackWidget> createState() => _TapFeedbackWidgetState();
}

class _TapFeedbackWidgetState extends State<TapFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Shimmer loading animation widget
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerWidget({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Bounce animation widget
class BounceAnimationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BounceAnimationWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<BounceAnimationWidget> createState() => _BounceAnimationWidgetState();
}

class _BounceAnimationWidgetState extends State<BounceAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation widget
class PulseAnimationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimationWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  }) : super(key: key);

  @override
  State<PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<PulseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
