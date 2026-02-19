import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// A centralized collection of text styles used throughout the application.
///
/// This class defines the typography scale to ensure visual consistency across the UI.
/// All styles use the Roboto font and the default text color from [AppColors].
class AppTextStyles {
  /// Large title text style with regular weight.
  static const titleRegular = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Large title text style with medium weight.
  static const titleMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Large title text style with bold weight.
  static const titleBold = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Header text style with regular weight.
  static const headerRegular = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Header text style with medium weight.
  static const headerMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Header text style with bold weight.
  static const headerBold = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Subheader text style with regular weight.
  static const subheaderRegular = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Subheader text style with medium weight.
  static const subheaderMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Subheader text style with bold weight.
  static const subheaderBold = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Body text style with regular weight.
  static const textRegular = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Body text style with medium weight.
  static const textMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Body text style with bold weight.
  static const textBold = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Footer text style with regular weight.
  static const footerRegular = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Footer text style with medium weight.
  static const footerMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );

  /// Footer text style with bold weight.
  static const footerBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.nineHundred,
    fontFamily: "Roboto",
  );
}
