import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BlurredModal extends StatelessWidget {
  final Widget child;
  final bool barrierDismissible;
  final Color? barrierColor;
  final double borderRadius;
  final EdgeInsets? padding;

  const BlurredModal({
    Key? key,
    required this.child,
    this.barrierDismissible = true,
    this.barrierColor,
    this.borderRadius = 32.0,
    this.padding,
  }) : super(key: key);

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    double borderRadius = 32.0,
    EdgeInsets? padding,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (context) => BlurredModal(
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        borderRadius: borderRadius,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: GestureDetector(
            onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                color: barrierColor ?? Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
        // Modal content
        Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: padding ?? EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Blurred bottom sheet modal
class BlurredBottomSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final double? height;

  const BlurredBottomSheet({
    Key? key,
    required this.child,
    this.borderRadius = 32.0,
    this.padding,
    this.height,
  }) : super(key: key);

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double borderRadius = 32.0,
    EdgeInsets? padding,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => BlurredBottomSheet(
        borderRadius: borderRadius,
        padding: padding,
        height: height,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
        // Bottom sheet content
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              height: height ?? 50.h,
              padding: padding ?? EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 12.w,
                    height: 0.5.h,
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Content
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading overlay with blur effect
class BlurredLoadingOverlay extends StatelessWidget {
  final String? message;
  final Widget? customLoader;

  const BlurredLoadingOverlay({
    Key? key,
    this.message,
    this.customLoader,
  }) : super(key: key);

  static void show(BuildContext context, {String? message, Widget? customLoader}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => BlurredLoadingOverlay(
        message: message,
        customLoader: customLoader,
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        // Loading content
        Center(
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                customLoader ?? 
                SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (message != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
