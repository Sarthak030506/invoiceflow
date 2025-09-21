import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class that contains all theme configurations for the financial application.
class AppTheme {
  AppTheme._();

  // Sophisticated Color Palette - Gentle & Professional
  // Primary Colors - Deep Navy & Serene Blue
  // Updated to vibrant modern blue shades
  static const Color primaryLight = Color(0xFF0F62FE); // Vibrant Blue
  static const Color primaryVariantLight = Color(0xFF2D8CFF); // Lighter Blue
  static const Color primaryAccentLight = Color(0xFF8CC8FF); // Soft Sky Blue

  // Secondary Colors - Sophisticated Green & Gold
  // Updated to emerald green
  static const Color secondaryLight = Color(0xFF10B981); // Emerald
  static const Color secondaryVariantLight = Color(0xFF059669); // Deep Emerald
  static const Color accentGoldLight = Color(0xFFB8860B); // Sophisticated Gold
  static const Color accentGoldVariantLight = Color(0xFFD4AF37); // Light Gold

  // Background Colors - Off-whites & Gentle Silvers
  static const Color backgroundLight = Color(0xFFFAFAFC); // Soft Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariantLight = Color(0xFFF5F7FA); // Gentle Silver
  static const Color surfaceElevatedLight = Color(0xFFF8F9FB); // Elevated Surface

  // Status Colors - Sophisticated variants
  static const Color errorLight = Color(0xFFB85450); // Muted Red
  static const Color successLight = Color(0xFF5D8A72); // Sage Green (reused)
  static const Color warningLight = Color(0xFFB8860B); // Gold Warning
  static const Color infoLight = Color(0xFF4A90B8); // Serene Blue (reused)

  // Text Colors - Rich but gentle
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF1A1A1A); // Soft Black
  static const Color onSurfaceLight = Color(0xFF2D3748); // Charcoal
  static const Color onErrorLight = Color(0xFFFFFFFF);

  // Dark Theme - Sophisticated & Gentle
  // Primary Colors - Lighter Navy & Bright Serene Blue
  static const Color primaryDark = Color(0xFF60A5FA); // Light Blue (dark theme)
  static const Color primaryVariantDark = Color(0xFF3B82F6); // Blue
  static const Color primaryAccentDark = Color(0xFF93C5FD); // Lighter Blue

  // Secondary Colors - Softer variants
  static const Color secondaryDark = Color(0xFF34D399); // Light Emerald
  static const Color secondaryVariantDark = Color(0xFF10B981); // Emerald
  static const Color accentGoldDark = Color(0xFFD4AF37); // Light Gold
  static const Color accentGoldVariantDark = Color(0xFFE6C84A); // Bright Gold

  // Background Colors - Rich darks with sophistication
  static const Color backgroundDark = Color(0xFF0F1419); // Deep Charcoal
  static const Color surfaceDark = Color(0xFF1A2027); // Dark Surface
  static const Color surfaceVariantDark = Color(0xFF242B33); // Dark Silver
  static const Color surfaceElevatedDark = Color(0xFF2A3138); // Elevated Dark

  // Status Colors - Muted for dark theme
  static const Color errorDark = Color(0xFFD47570); // Soft Red
  static const Color successDark = Color(0xFF7BA68A); // Light Sage
  static const Color warningDark = Color(0xFFD4AF37); // Light Gold
  static const Color infoDark = Color(0xFF6BB6D6); // Light Serene Blue

  // Text Colors - Soft whites and grays
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFFFFFFFF);
  static const Color onBackgroundDark = Color(0xFFF7FAFC); // Soft White
  static const Color onSurfaceDark = Color(0xFFE2E8F0); // Light Gray
  static const Color onErrorDark = Color(0xFFFFFFFF);

  // Card and dialog colors - Enhanced with surface variants
  static const Color cardLight = surfaceLight;
  static const Color cardElevatedLight = surfaceElevatedLight;
  static const Color cardDark = surfaceDark;
  static const Color cardElevatedDark = surfaceElevatedDark;
  static const Color dialogLight = surfaceLight;
  static const Color dialogDark = surfaceDark;

  // Shadow colors - Softer, more sophisticated
  static const Color shadowLight = Color(0x1A1B3A57); // Navy-tinted shadow
  static const Color shadowDark = Color(0x404A90B8); // Blue-tinted shadow

  // Divider colors - Gentle and refined
  static const Color dividerLight = Color(0x1F2D3748); // Soft charcoal
  static const Color dividerDark = Color(0x3FE2E8F0); // Soft light gray

  // Text colors - Rich typography hierarchy
  static const Color textPrimaryLight = onSurfaceLight; // Charcoal
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate Gray
  static const Color textDisabledLight = Color(0xFF94A3B8); // Light Slate
  static const Color textHintLight = Color(0xFFCBD5E1); // Very Light Slate

  static const Color textPrimaryDark = onSurfaceDark; // Soft White
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Light Slate
  static const Color textDisabledDark = Color(0xFF94A3B8); // Slate Gray
  static const Color textHintDark = Color(0xFF64748B); // Dark Slate

  // Gradient Definitions - Sophisticated & Subtle
  // Primary Gradients
  static const LinearGradient primaryGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryVariantLight],
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryVariantDark],
  );

  // Background Gradients - Soft and elegant
  static const LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBFCFE), backgroundLight],
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2027), backgroundDark],
  );

  // Card Gradients - Subtle elevation
  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLight, Color(0xFFFDFDFE)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceDark, Color(0xFF1F252C)],
  );

  // Accent Gradients - Gold sophistication
  static const LinearGradient goldGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGoldLight, accentGoldVariantLight],
  );

  static const LinearGradient goldGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGoldDark, accentGoldVariantDark],
  );

  // Success Gradient - Sage green elegance
  static const LinearGradient successGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, secondaryVariantLight],
  );

  static const LinearGradient successGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successDark, secondaryVariantDark],
  );

  /// Light theme with sophisticated color palette
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryAccentLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onSecondaryLight,
      secondaryContainer: secondaryVariantLight,
      onSecondaryContainer: onSecondaryLight,
      tertiary: accentGoldLight,
      onTertiary: onPrimaryLight,
      tertiaryContainer: accentGoldVariantLight,
      onTertiaryContainer: onPrimaryLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: surfaceVariantLight,
      surfaceContainer: surfaceElevatedLight,
      onSurfaceVariant: textSecondaryLight,
      outline: dividerLight,
      outlineVariant: Color(0x0F2D3748),
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,
    // Enhanced rounded visuals with sophisticated palette
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryLight,
      foregroundColor: onPrimaryLight,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: onPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 4.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryLight,
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: onPrimaryLight,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primaryLight,
        elevation: 2.0,
        shadowColor: shadowLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: primaryLight, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: true),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: errorLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textDisabledLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.inter(
        color: errorLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dialogLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
    ),
  );

  /// Dark theme with sophisticated color palette
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryAccentDark,
      onPrimaryContainer: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryVariantDark,
      onSecondaryContainer: onSecondaryDark,
      tertiary: accentGoldDark,
      onTertiary: onPrimaryDark,
      tertiaryContainer: accentGoldVariantDark,
      onTertiaryContainer: onPrimaryDark,
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: surfaceVariantDark,
      surfaceContainer: surfaceElevatedDark,
      onSurfaceVariant: textSecondaryDark,
      outline: dividerDark,
      outlineVariant: Color(0x1FE2E8F0),
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
      ),
      iconTheme: const IconThemeData(color: primaryDark),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondaryDark,
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: onPrimaryDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryDark,
        backgroundColor: primaryDark,
        elevation: 2.0,
        shadowColor: shadowDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: primaryDark, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: false),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: errorDark, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: const BorderSide(color: errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textDisabledDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.inter(
        color: errorDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dialogDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
    ),
  );

  /// Helper method to build text theme based on brightness
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textPrimary = isLight ? textPrimaryLight : textPrimaryDark;
    final Color textSecondary =
        isLight ? textSecondaryLight : textSecondaryDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
      // Display styles - Inter Bold for major headings
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),

      // Headline styles - Inter SemiBold for section headers
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),

      // Title styles - Inter Medium for card titles and important labels
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),

      // Body styles - Inter Regular for main content
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.4,
      ),

      // Label styles - Inter Medium for buttons and labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textDisabled,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Custom text styles for financial data display
  static TextStyle financialDataStyle(
      {required bool isLight, double fontSize = 16}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: isLight ? textPrimaryLight : textPrimaryDark,
      letterSpacing: 0.5,
    );
  }

  /// Custom text style for invoice numbers and IDs
  static TextStyle invoiceNumberStyle(
      {required bool isLight, double fontSize = 14}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: isLight ? textSecondaryLight : textSecondaryDark,
      letterSpacing: 0.5,
    );
  }

  /// Success color getter
  static Color getSuccessColor(bool isLight) {
    return isLight ? successLight : successDark;
  }

  /// Warning color getter
  static Color getWarningColor(bool isLight) {
    return isLight ? warningLight : warningDark;
  }

  /// Info color getter
  static Color getInfoColor(bool isLight) {
    return isLight ? infoLight : infoDark;
  }

  /// Accent gold color getter
  static Color getAccentGoldColor(bool isLight) {
    return isLight ? accentGoldLight : accentGoldDark;
  }

  /// Primary accent color getter
  static Color getPrimaryAccentColor(bool isLight) {
    return isLight ? primaryAccentLight : primaryAccentDark;
  }

  /// Surface variant color getter
  static Color getSurfaceVariantColor(bool isLight) {
    return isLight ? surfaceVariantLight : surfaceVariantDark;
  }

  /// Surface elevated color getter
  static Color getSurfaceElevatedColor(bool isLight) {
    return isLight ? surfaceElevatedLight : surfaceElevatedDark;
  }

  /// Get primary gradient based on theme brightness
  static LinearGradient getPrimaryGradient(bool isLight) {
    return isLight ? primaryGradientLight : primaryGradientDark;
  }

  /// Get background gradient based on theme brightness
  static LinearGradient getBackgroundGradient(bool isLight) {
    return isLight ? backgroundGradientLight : backgroundGradientDark;
  }

  /// Get card gradient based on theme brightness
  static LinearGradient getCardGradient(bool isLight) {
    return isLight ? cardGradientLight : cardGradientDark;
  }

  /// Get gold gradient based on theme brightness
  static LinearGradient getGoldGradient(bool isLight) {
    return isLight ? goldGradientLight : goldGradientDark;
  }

  /// Get success gradient based on theme brightness
  static LinearGradient getSuccessGradient(bool isLight) {
    return isLight ? successGradientLight : successGradientDark;
  }

  /// Create sophisticated container decoration
  static BoxDecoration createSophisticatedContainer({
    required bool isLight,
    Gradient? gradient,
    double borderRadius = 24.0,
    bool includeElevation = true,
  }) {
    return BoxDecoration(
      gradient: gradient ?? getCardGradient(isLight),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: includeElevation ? [
        BoxShadow(
          color: isLight 
            ? shadowLight.withValues(alpha: 0.15)
            : shadowDark.withValues(alpha: 0.15),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isLight 
            ? shadowLight.withValues(alpha: 0.05)
            : shadowDark.withValues(alpha: 0.05),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ] : null,
      border: Border.all(
        color: isLight 
          ? dividerLight.withValues(alpha: 0.3)
          : dividerDark.withValues(alpha: 0.3),
        width: 0.5,
      ),
    );
  }
}

