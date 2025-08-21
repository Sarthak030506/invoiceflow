import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Extension class that provides additional rounded theme components
/// to ensure comprehensive rounded aesthetics throughout the app
class RoundedThemeExtensions {
  RoundedThemeExtensions._();

  /// Standard border radius used throughout the app for consistency
  static const double standardRadius = 24.0;
  static const double smallRadius = 12.0;
  static const double largeRadius = 32.0;

  /// Get additional theme data for light theme
  static ThemeData enhanceLightTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Enhanced chip theme with rounded aesthetics
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.surfaceLight,
        selectedColor: AppTheme.primaryLight,
        disabledColor: AppTheme.textDisabledLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        side: const BorderSide(color: AppTheme.dividerLight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Enhanced snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTheme.surfaceDark,
        contentTextStyle: GoogleFonts.inter(
          color: AppTheme.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Enhanced popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        elevation: 8.0,
        shadowColor: AppTheme.shadowLight,
      ),

      // Enhanced list tile theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        tileColor: AppTheme.surfaceLight,
      ),

      // Enhanced expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        backgroundColor: AppTheme.surfaceLight,
        collapsedBackgroundColor: AppTheme.surfaceLight,
      ),

      // Enhanced tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicator: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Enhanced switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.onPrimaryLight;
          }
          return AppTheme.textSecondaryLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryLight;
          }
          return AppTheme.dividerLight;
        }),
      ),

      // Enhanced checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppTheme.onPrimaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),

      // Enhanced radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryLight;
          }
          return AppTheme.textSecondaryLight;
        }),
      ),

      // Enhanced slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppTheme.primaryLight,
        inactiveTrackColor: AppTheme.dividerLight,
        thumbColor: AppTheme.primaryLight,
        overlayColor: AppTheme.primaryLight.withOpacity(0.2),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
      ),

      // Enhanced progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppTheme.primaryLight,
        linearTrackColor: AppTheme.dividerLight,
        circularTrackColor: AppTheme.dividerLight,
      ),

      // Enhanced divider theme
      dividerTheme: DividerThemeData(
        color: AppTheme.dividerLight,
        thickness: 1.0,
        space: 1.0,
      ),

      // Enhanced tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        textStyle: GoogleFonts.inter(
          color: AppTheme.textPrimaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Get additional theme data for dark theme
  static ThemeData enhanceDarkTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Enhanced chip theme with rounded aesthetics
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.surfaceDark,
        selectedColor: AppTheme.primaryDark,
        disabledColor: AppTheme.textDisabledDark,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        side: const BorderSide(color: AppTheme.dividerDark),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Enhanced snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTheme.surfaceLight,
        contentTextStyle: GoogleFonts.inter(
          color: AppTheme.textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Enhanced popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        elevation: 8.0,
        shadowColor: AppTheme.shadowDark,
      ),

      // Enhanced list tile theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        tileColor: AppTheme.surfaceDark,
      ),

      // Enhanced expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        backgroundColor: AppTheme.surfaceDark,
        collapsedBackgroundColor: AppTheme.surfaceDark,
      ),

      // Enhanced tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppTheme.primaryDark,
        unselectedLabelColor: AppTheme.textSecondaryDark,
        indicator: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Enhanced switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.onPrimaryDark;
          }
          return AppTheme.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryDark;
          }
          return AppTheme.dividerDark;
        }),
      ),

      // Enhanced checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryDark;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppTheme.onPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),

      // Enhanced radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.primaryDark;
          }
          return AppTheme.textSecondaryDark;
        }),
      ),

      // Enhanced slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppTheme.primaryDark,
        inactiveTrackColor: AppTheme.dividerDark,
        thumbColor: AppTheme.primaryDark,
        overlayColor: AppTheme.primaryDark.withOpacity(0.2),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
      ),

      // Enhanced progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppTheme.primaryDark,
        linearTrackColor: AppTheme.dividerDark,
        circularTrackColor: AppTheme.dividerDark,
      ),

      // Enhanced divider theme
      dividerTheme: DividerThemeData(
        color: AppTheme.dividerDark,
        thickness: 1.0,
        space: 1.0,
      ),

      // Enhanced tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        textStyle: GoogleFonts.inter(
          color: AppTheme.textPrimaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Helper method to create rounded container decoration
  static BoxDecoration createRoundedDecoration({
    required Color backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
    double radius = standardRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: shadows,
    );
  }

  /// Helper method to create iOS-style card shadows
  static List<BoxShadow> createCardShadows({required bool isLight}) {
    return [
      BoxShadow(
        color: isLight ? AppTheme.shadowLight : AppTheme.shadowDark,
        offset: const Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isLight 
            ? AppTheme.shadowLight.withOpacity(0.1) 
            : AppTheme.shadowDark.withOpacity(0.1),
        offset: const Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];
  }

  /// Helper method to create rounded image decoration
  static BoxDecoration createRoundedImageDecoration({
    required double radius,
    Color? borderColor,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    );
  }

  /// Helper method to create pill-shaped button decoration
  static BoxDecoration createPillDecoration({
    required Color backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(50.0), // Pill shape
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
    );
  }
}