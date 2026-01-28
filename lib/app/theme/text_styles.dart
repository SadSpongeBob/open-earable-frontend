import 'package:flutter/material.dart';
import '../constants/colors.dart';
class GlobalTextStyles {
  static const titleBold = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const headerMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const cardTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const subHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const subHeaderMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const text = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const textMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const footnote = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  static const footnoteMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );
}
class AuthTextStyles {
  static const title = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  // used for general body text
  static const body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  // used for links like "Sign Up" or "Forgot Password?"
  static const link = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );

  // placeholder for input fields
  static const fieldHint = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.fieldHint,
    fontFamily: "Roboto",
  );

  // input text style for text fields
  static const fieldInput = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.fieldText,
    fontFamily: "Roboto",
  );

  static const button = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Color(0xFFF2F2F2),
    fontFamily: "Roboto",
  );
}
