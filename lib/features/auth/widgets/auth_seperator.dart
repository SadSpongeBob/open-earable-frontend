import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class AuthSeparator extends StatelessWidget {
  const AuthSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(width: 90),
        Expanded(child: Divider(thickness: 2, color: Colors.black)),
        SizedBox(width: 4),
        Text("or", style: AuthTextStyles.body),
        SizedBox(width: 4),
        Expanded(child: Divider(thickness: 2, color: Colors.black)),
        SizedBox(width: 90),
      ],
    );
  }
}
