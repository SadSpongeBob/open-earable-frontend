import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A tappable button representing "Users".
///
/// Calls [onTap] when pressed.
class UsersButton extends StatelessWidget {
  const UsersButton({super.key, required this.onTap});

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 103,
        height: 109,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.fifty,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.fiveHundred,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/user.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 4),
            const Text('Users', style: AppTextStyles.footerBold),
          ],
        ),
      ),
    );
  }
}
