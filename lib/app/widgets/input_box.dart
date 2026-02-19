import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../constants/colors.dart';

/// A reusable, styled text input field for forms.
///
/// Parameters:
/// - [controller]: The [TextEditingController] that holds the current value of the input field.
/// - [hint]: Placeholder text displayed when the field is empty.
/// - [validator]: Optional validation function. Returns a `String` error message if invalid, or `null` if valid.
/// - [obscureText]: Whether to hide the input text (e.g., for passwords). Defaults to `false`.
/// - [suffixIcon]: Optional widget displayed at the end of the input field (e.g., show/hide password button).
/// - [keyboardType]: The type of keyboard to show (e.g., `TextInputType.emailAddress`). Defaults to `TextInputType.text`.
/// - [textAlign]: Alignment of the input text. Defaults to `TextAlign.start`.
/// - [focusNode]: Optional [FocusNode] to manage focus programmatically.
/// - [textInputAction]: Optional [TextInputAction] to customize the keyboard action button (e.g., done, next).
/// - [onSubmitted]: Optional callback invoked when the user submits the field via the keyboard.
class InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const InputBox({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: textAlign,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
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
