import 'package:flutter/material.dart';

/// A centralized color palette used throughout the application.
///
/// This class defines the primary brand colors and a grayscale scale
/// (0–900) to ensure consistent theming and visual hierarchy across the UI.
class AppColors {
  /// Primary brand color used for main actions and highlights.
  static const Color primary = Color(0xFFFF4442);
  /// Secondary brand color used for accents and secondary elements.
  static const Color secondary = Color(0xFFAF83B9);
  /// Success/positive state color.
  static const Color green = Color(0xFF4CAF50);

  /// Chart colors
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color indigo = Color(0xFF536DFE);

  /// Grayscale colors from 0 till 900
  static const Color zero = Color(0xFFFFFFFF);
  static const Color fifty = Color(0xFFF2F2F2);
  static const Color hundred = Color(0xFFE6E6E6);
  static const Color twoHundred = Color(0xFFD1D1D1);
  static const Color threeHundred = Color(0xFFBCBABA);
  static const Color fourHundred = Color(0xFFA3A3A3);
  static const Color fiveHundred = Color(0xFF8F8F8F);
  static const Color sixHundred = Color(0xFF6E6E6E);
  static const Color sevenHundred = Color(0xFF4E4E4E);
  static const Color eightHundred = Color(0xFF2E2E2E);
  static const Color nineHundred = Color(0xFF1F1F1F);
}
