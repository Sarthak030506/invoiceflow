import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LoadingAnimations {
  /// Creates a shimmer skeleton widget
  static Widget createSkeleton({
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    return _ShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Creates a pulsing loading indicator
  static Widget createPulseLoader({
    Color? color,
    double size = 50.0,
  }) {
    return _PulseLoader(
      color: color ?? Colors.blue,
      size: size,
    );
  }

  /// Creates a wave loading indicator
  static Widget createWaveLoader({
    Color? color,
    double size = 50.0,
  }) {
    return _WaveLoader(
      color: color ?? Colors.blue,
      size: size,
    );
  }

  /// Creates a progress bar with custom curves
  static Widget createProgressBar({
    required double progress,
    Color? color,
    Color? backgroundColor,
    double height = 8.0,
    double borderRadius = 4.0,
  }) {
    return _CustomProgressBar(
      progress: progress,
      color: color ?? Colors.blue,
      backgroundColor: backgroundColor ?? Colors.grey.shade300,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerSkeleton({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PulseLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseLoader({
    required this.color,
    required this.size,
  });

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

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
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.2 + (_animation.value * 0.8)),
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _WaveLoader({
    required this.color,
    required this.size,
  });

  @override
  State<_WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<_WaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final progress = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.size * 0.1),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _CustomProgressBar extends StatefulWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;
  final double borderRadius;

  const _CustomProgressBar({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_CustomProgressBar> createState() => _CustomProgressBarState();
}

class _CustomProgressBarState extends State<_CustomProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: _currentProgress, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(_CustomProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _currentProgress, end: widget.progress)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
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
        _currentProgress = _animation.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _animation.value.clamp(0.0, 1.0),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
