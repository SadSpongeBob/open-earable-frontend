import 'package:flutter/material.dart';
class GlobalAppBarStyles {
  static BoxDecoration appBarDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((0.15 * 255).round()),
        blurRadius: 12,
      ),
    ],
  );
  static const appBarText = TextStyle(
    color: Color(0xFFFF4442),
    fontSize: 16,
    fontFamily: 'Roboto',
  );
  static const appBarTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1F1F),
    fontFamily: "Roboto",
  );
}
