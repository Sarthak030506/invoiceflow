import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension class for sophisticated design elements including gradients,
/// advanced shadows, and refined styling components
class SophisticatedThemeExtensions {
  SophisticatedThemeExtensions._();

  /// Get sophisticated container decoration with gradient background
  static BoxDecoration createSophisticatedContainer({
    required bool isLight,
    Gradient? gradient,
    double borderRadius = 24.0,
    bool includeElevation = true,
  }) {
    return BoxDecoration(
      gradient: gradient ?? (isLight 
        ? AppTheme.cardGradientLight 
        : AppTheme.cardGradientDark),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: includeElevation ? createElevatedShadows(isLight: isLight) : null,
      border: Border.all(
        color: isLight 
          ? AppTheme.dividerLight.withValues(alpha: 0.3)
          : AppTheme.dividerDark.withValues(alpha: 0.3),
        width: 0.5,
      ),
    );
  }

  /// Create sophisticated card decoration with gradient and depth
  static BoxDecoration createSophisticatedCard({
    required bool isLight,
    bool isElevated = false,
    double borderRadius = 24.0,
  }) {
    return BoxDecoration(
      gradient: isLight 
        ? AppTheme.cardGradientLight 
        : AppTheme.cardGradientDark,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isElevated 
        ? createElevatedShadows(isLight: isLight)
        : createSubtleShadows(isLight: isLight),
      border: Border.all(
        color: isLight 
          ? const Color(0x0A1B3A57) // Very subtle navy border
          : const Color(0x1A4A90B8), // Very subtle blue border
        width: 0.5,
      ),
    );
  }

  /// Create sophisticated app bar decoration with gradient
  static BoxDecoration createSophisticatedAppBar({
    required bool isLight,
    double borderRadius = 24.0,
  }) {
    return BoxDecoration(
      gradient: isLight 
        ? AppTheme.primaryGradientLight 
        : AppTheme.primaryGradientDark,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(borderRadius),
      ),
      boxShadow: [
        BoxShadow(
          color: isLight 
            ? AppTheme.shadowLight.withValues(alpha: 0.3)
            : AppTheme.shadowDark.withValues(alpha: 0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Create sophisticated button decoration with gradient
  static BoxDecoration createSophisticatedButton({
    required bool isLight,
    required ButtonType type,
    double borderRadius = 24.0,
    bool isPressed = false,
  }) {
    Gradient gradient;
    List<BoxShadow> shadows;

    switch (type) {
      case ButtonType.primary:
        gradient = isLight 
          ? AppTheme.primaryGradientLight 
          : AppTheme.primaryGradientDark;
        break;
      case ButtonType.secondary:
        gradient = isLight 
          ? AppTheme.successGradientLight 
          : AppTheme.successGradientDark;
        break;
      case ButtonType.accent:
        gradient = isLight 
          ? AppTheme.goldGradientLight 
          : AppTheme.goldGradientDark;
        break;
    }

    shadows = isPressed 
      ? createPressedShadows(isLight: isLight)
      : createButtonShadows(isLight: isLight);

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: shadows,
    );
  }

  /// Create sophisticated background decoration
  static BoxDecoration createSophisticatedBackground({
    required bool isLight,
  }) {
    return BoxDecoration(
      gradient: isLight 
        ? AppTheme.backgroundGradientLight 
        : AppTheme.backgroundGradientDark,
    );
  }

  /// Create subtle shadows for cards and containers
  static List<BoxShadow> createSubtleShadows({required bool isLight}) {
    return [
      BoxShadow(
        color: isLight 
          ? AppTheme.shadowLight.withValues(alpha: 0.15)
          : AppTheme.shadowDark.withValues(alpha: 0.15),
        offset: const Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isLight 
          ? AppTheme.shadowLight.withValues(alpha: 0.05)
          : AppTheme.shadowDark.withValues(alpha: 0.05),
        offset: const Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];
  }

  /// Create elevated shadows for prominent elements
  static List<BoxShadow> createElevatedShadows({required bool isLight}) {
    return [
      BoxShadow(
        color: isLight 
          ? AppTheme.shadowLight.withValues(alpha: 0.25)
          : AppTheme.shadowDark.withValues(alpha: 0.25),
        offset: const Offset(0, 8),
        blurRadius: 24,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isLight 
          ? AppTheme.shadowLight.withValues(alpha: 0.1)
          : AppTheme.shadowDark.withValues(alpha: 0.1),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }

  /// Create button-specific shadows
  static List<BoxShadow> createButtonShadows({required bool isLight}) {
    return [
      BoxShadow(
        color: isLight 
          ? AppTheme.primaryLight.withValues(alpha: 0.3)
          : AppTheme.primaryDark.withValues(alpha: 0.3),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isLight 
          ? AppTheme.shadowLight.withValues(alpha: 0.1)
          : AppTheme.shadowDark.withValues(alpha: 0.1),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
  }

  /// Create pressed button shadows
  static List<BoxShadow> createPressedShadows({required bool isLight}) {
    return [
      BoxShadow(
        color: isLight 
          ? AppTheme.primaryLight.withValues(alpha: 0.2)
          : AppTheme.primaryDark.withValues(alpha: 0.2),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
  }

  /// Create sophisticated text styles with appropriate colors
  static TextStyle createSophisticatedTextStyle({
    required bool isLight,
    required SophisticatedTextType type,
    double? fontSize,
  }) {
    Color textColor;
    FontWeight fontWeight;
    double defaultSize;

    switch (type) {
      case SophisticatedTextType.headline:
        textColor = isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
        fontWeight = FontWeight.w700;
        defaultSize = 24;
        break;
      case SophisticatedTextType.title:
        textColor = isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
        fontWeight = FontWeight.w600;
        defaultSize = 18;
        break;
      case SophisticatedTextType.body:
        textColor = isLight ? AppTheme.textSecondaryLight : AppTheme.textSecondaryDark;
        fontWeight = FontWeight.w400;
        defaultSize = 16;
        break;
      case SophisticatedTextType.caption:
        textColor = isLight ? AppTheme.textDisabledLight : AppTheme.textDisabledDark;
        fontWeight = FontWeight.w400;
        defaultSize = 14;
        break;
      case SophisticatedTextType.accent:
        textColor = isLight ? AppTheme.accentGoldLight : AppTheme.accentGoldDark;
        fontWeight = FontWeight.w600;
        defaultSize = 16;
        break;
    }

    return TextStyle(
      color: textColor,
      fontSize: fontSize ?? defaultSize,
      fontWeight: fontWeight,
      letterSpacing: type == SophisticatedTextType.headline ? -0.5 : 0.0,
    );
  }

  /// Create gradient shimmer effect for loading states
  static LinearGradient createShimmerGradient({required bool isLight}) {
    return LinearGradient(
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      colors: isLight
        ? [
            AppTheme.surfaceVariantLight,
            AppTheme.surfaceElevatedLight,
            AppTheme.surfaceVariantLight,
          ]
        : [
            AppTheme.surfaceVariantDark,
            AppTheme.surfaceElevatedDark,
            AppTheme.surfaceVariantDark,
          ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}

/// Enum for button types
enum ButtonType {
  primary,
  secondary,
  accent,
}

/// Enum for sophisticated text types
enum SophisticatedTextType {
  headline,
  title,
  body,
  caption,
  accent,
}
