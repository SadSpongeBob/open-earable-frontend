import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  final bool enabled;

  const AuthButton({
    super.key,
    required this.text,
    this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = enabled && !loading;

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.black // enabled state
              : const Color(0xFF6E6E6E),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.black),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: AuthTextStyles.button.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
