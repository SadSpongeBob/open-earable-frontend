import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class AuthFooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool bold;

  const AuthFooterLink({
    super.key,
    required this.text,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: bold ? AppTextStyles.footerBold : AppTextStyles.footerRegular,
      ),
    );
  }
}
