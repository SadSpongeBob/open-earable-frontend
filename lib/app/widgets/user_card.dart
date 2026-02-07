import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';

class UserCard extends StatelessWidget {
  final Widget child;

  const UserCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double cardWidth = width * 0.85 > 500 ? 500 : width * 0.85;

    return Center(
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 50),
        decoration: BoxDecoration(
          color: AppColors.fifty,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: AppColors.fiveHundred,
              blurRadius: 50,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}
