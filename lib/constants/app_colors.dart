import 'package:flutter/material.dart';

class AppColors {
  // Blue-Green Theme Colors
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryGreen = Color(0xFF26A69A);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color lightGreen = Color(0xFF4DB6AC);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color darkGreen = Color(0xFF00695C);
  
  // Accent Colors
  static const Color teal = Color(0xFF00BCD4);
  static const Color deepTeal = Color(0xFF00838F);
  
  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGreenGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF26A69A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightBlueGreenGradient = LinearGradient(
    colors: [Color(0xFFE3F2FD), Color(0xFFE0F2F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text Colors for Contrast
  static const Color textOnBlue = Colors.white;
  static const Color textOnGreen = Colors.white;
  static const Color textOnLight = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
}