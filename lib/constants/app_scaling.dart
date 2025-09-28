import 'package:flutter/material.dart';

class AppScaling {
  // Text sizes (sp)
  static const double h1 = 20.0; // Titles
  static const double h2 = 16.0; // Subtitles  
  static const double body = 14.0; // Body text
  static const double small = 12.0; // Small text
  static const double button = 14.0; // Button text

  // Spacing (dp)
  static const double spacing = 8.0;
  static const double spacingSmall = 4.0;
  static const double spacingLarge = 12.0;

  // Component sizes (dp)
  static const double buttonHeight = 44.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 28.0;
  static const double cardPadding = 12.0;
  static const double inputHeight = 44.0;

  // Margins and padding
  static const EdgeInsets defaultPadding = EdgeInsets.all(12.0);
  static const EdgeInsets cardMargin = EdgeInsets.all(8.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );
  static const EdgeInsets cardPadding2 = EdgeInsets.all(14.0);
  static const EdgeInsets sectionMargin = EdgeInsets.symmetric(vertical: 8.0);

  // Opacity values
  static const double maxOpacity = 1.0;
  static const double minOpacity = 0.0;
  static const double highEmphasis = 0.87;
  static const double mediumEmphasis = 0.60;
  static const double lowEmphasis = 0.38;
  static const double disabled = 0.38;
  
  // Utility methods
  static double clampOpacity(double value) {
    return value.clamp(minOpacity, maxOpacity);
  }
  
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(clampOpacity(opacity));
  }
  
  static Color emphasize(Color color, {double emphasis = highEmphasis}) {
    return color.withOpacity(clampOpacity(emphasis));
  }
}
