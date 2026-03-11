import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

class UsersButton extends StatelessWidget {
  const UsersButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 103,
        height: 109,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Image.asset(
                'assets/images/user.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 2),
            const Flexible(
              child: Text(
                'Users',
                style: AppTextStyles.footerBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}