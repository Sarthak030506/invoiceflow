import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EnhancedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EnhancedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _scaleAnimations = _controllers
        .map((controller) => Tween<double>(begin: 1.0, end: 1.1).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();

    // Animate the initially selected item
    _controllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(EnhancedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor?.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 7.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Invoices')),
              Expanded(child: _buildNavItem(2, Icons.analytics_outlined, Icons.analytics, 'Analytics')),
              Expanded(child: _buildNavItem(3, Icons.people_outlined, Icons.people, 'Customers')),
              Expanded(child: _buildNavItem(4, Icons.person_outlined, Icons.person, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, IconData activeIcon, String label) {
    final isSelected = widget.currentIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? theme.bottomNavigationBarTheme.selectedItemColor
                          : theme.bottomNavigationBarTheme.unselectedItemColor,
                      size: 5.2.w,
                    ),
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}