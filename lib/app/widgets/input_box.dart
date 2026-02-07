import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../constants/colors.dart';

class InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextAlign textAlign;

  const InputBox({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: AppTextStyles.textRegular,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.textRegular.copyWith(
          color: AppColors.sevenHundred,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
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
      borderSide: const BorderSide(width: 3, color: AppColors.nineHundred),
    );
  }
}
