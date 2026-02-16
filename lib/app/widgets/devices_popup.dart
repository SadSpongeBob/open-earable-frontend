import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/devices.dart';

class DevicesPopup extends StatelessWidget {
  const DevicesPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      borderRadius: BorderRadius.circular(36),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 300,
        height: 550,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: AppColors.fifty,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Column(
          children: [
            const Text('Devices', style: AppTextStyles.headerRegular),
            const SizedBox(height: 30),
            const Devices(),
          ],
        ),
      ),
    );
  }
}
