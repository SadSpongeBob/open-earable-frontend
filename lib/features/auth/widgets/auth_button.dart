import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;

  const AuthButton({
    super.key,
    required this.text,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF6E6E6E),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFF1F1F1F)),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: AuthTextStyles.button),
      ),
    );
  }
}
