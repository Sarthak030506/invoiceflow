import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Reusable skeleton loader widgets for analytics screens with shimmer animation
class SkeletonLoader {
  /// Skeleton card for KPI-style cards
  static Widget kpiCard({IconData? icon, Color? color}) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null && color != null)
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color.withOpacity(0.5), size: 6.w),
                )
              else
                _shimmerBox(width: 12.w, height: 12.w, radius: 12),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 100, height: 14, radius: 4),
                    SizedBox(height: 6),
                    _shimmerBox(width: 70, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          _shimmerBox(width: 120, height: 32, radius: 8),
          SizedBox(height: 2.w),
          Row(
            children: [
              _shimmerBox(width: 16, height: 16, radius: 8),
              SizedBox(width: 2.w),
              _shimmerBox(width: 80, height: 14, radius: 4),
            ],
          ),
        ],
      ),
    );
  }

  /// Skeleton for list item (used in revenue lists, item lists, etc.)
  static Widget listItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _shimmerBox(width: 12.w, height: 12.w, radius: 8),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: double.infinity, height: 16, radius: 4),
                SizedBox(height: 8),
                _shimmerBox(width: 100, height: 12, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          _shimmerBox(width: 60, height: 20, radius: 4),
        ],
      ),
    );
  }

  /// Skeleton for chart placeholder
  static Widget chart({double? height}) {
    return Container(
      height: height ?? 30.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _shimmerBox(width: 60, height: 60, radius: 30),
            SizedBox(height: 2.h),
            _shimmerBox(width: 150, height: 16, radius: 4),
            SizedBox(height: 1.h),
            _shimmerBox(width: 100, height: 12, radius: 4),
          ],
        ),
      ),
    );
  }

  /// Skeleton for table row
  static Widget tableRow({int columns = 4}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 3.w, horizontal: 4.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: List.generate(
          columns,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: _shimmerBox(
                width: double.infinity,
                height: 14,
                radius: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton for inventory card
  static Widget inventoryCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 120, height: 18, radius: 4),
              _shimmerBox(width: 60, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 3.w),
          _shimmerBox(width: double.infinity, height: 14, radius: 4),
          SizedBox(height: 2.w),
          Row(
            children: [
              Expanded(child: _shimmerBox(width: double.infinity, height: 32, radius: 8)),
              SizedBox(width: 3.w),
              Expanded(child: _shimmerBox(width: double.infinity, height: 32, radius: 8)),
            ],
          ),
        ],
      ),
    );
  }

  /// Skeleton for due reminder card
  static Widget dueReminderCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 12.w, height: 12.w, radius: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: double.infinity, height: 16, radius: 4),
                    SizedBox(height: 6),
                    _shimmerBox(width: 100, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 80, height: 24, radius: 4),
              _shimmerBox(width: 100, height: 32, radius: 16),
            ],
          ),
        ],
      ),
    );
  }

  /// Basic shimmer box with animation
  static Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Full screen loader with multiple skeleton cards
  static Widget screen({
    required List<Widget> skeletonWidgets,
    EdgeInsets? padding,
  }) {
    return ListView(
      padding: padding ?? EdgeInsets.all(4.w),
      children: skeletonWidgets,
    );
  }
}

/// Shimmer animation widget
class _ShimmerWidget extends StatefulWidget {
  final Widget child;

  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
