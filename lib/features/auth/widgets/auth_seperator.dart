import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import '../../../app/theme/text_styles.dart';

class AuthSeparator extends StatelessWidget {
  const AuthSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(width: 75),
        Expanded(child: Divider(thickness: 2, color: AppColors.nineHundred)),
        SizedBox(width: 9),
        Text("or", style: AppTextStyles.footerRegular),
        SizedBox(width: 9),
        Expanded(child: Divider(thickness: 2, color: AppColors.nineHundred)),
        SizedBox(width: 75),
      ],
    );
  }
}
