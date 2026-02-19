import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

/// A tappable text widget that triggers [onTap] used in authentication pages
/// to provide footer links.
/// 
/// Parameters:
/// - [text]: The text to display for the footer link.
/// - [onTap]: The callback triggered when the user taps the text.
/// - [bold]: Whether the text should appear bold. Defaults to `false`.
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
