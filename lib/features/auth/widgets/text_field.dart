import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 21, fontFamily: "Roboto", fontWeight: FontWeight.w600,),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F1F1F),
          fontFamily: "Roboto",
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(36),
      borderSide: const BorderSide(
        width: 3,
        color: Color(0xFF1F1F1F),
      ),
    );
  }
}
