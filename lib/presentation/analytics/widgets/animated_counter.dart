import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _parseAndAnimate();
  }

  void _parseAndAnimate() {
    final numericValue = _extractNumericValue(widget.value);
    if (numericValue > 0) {
      _targetValue = numericValue;
      _controller.forward();
    }
  }

  double _extractNumericValue(String value) {
    final regex = RegExp(r'[\d,]+');
    final match = regex.firstMatch(value.replaceAll('₹', ''));
    if (match != null) {
      return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  String _formatValue(double value) {
    if (widget.value.contains('₹')) {
      return '₹${value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _targetValue * _animation.value;
        return Text(
          _formatValue(currentValue),
          style: widget.style,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}