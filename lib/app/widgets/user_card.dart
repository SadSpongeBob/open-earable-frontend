import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';

/// A reusable card container for user-related content.
///
/// [UserCard] displays its [child] inside a styled card with:
/// - A maximum width of 500px or 85% of the screen width (whichever is smaller),
/// - Rounded corners and a shadow for visual emphasis,
/// - Padding around the content,
/// - A scrollable area if the content overflows vertically.
/// 
/// Parameters:
/// - [child]: The content displayed inside the card.
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
