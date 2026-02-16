import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool loading;
  final bool canSave;
  final VoidCallback onBack;
  final Future<void> Function() onSave;

  const SettingsAppBar({
    super.key,
    required this.loading,
    required this.canSave,
    required this.onBack,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AppColors.fifty,
          boxShadow: [BoxShadow(color: AppColors.fiveHundred, blurRadius: 30)],
        ),
      ),
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: Row(
          children: [
            AppButton.dangerGhost(
              text: 'Back',
              onPressed: onBack,
              fullWidth: false,
              textStyle: AppTextStyles.footerMedium,
            ),
            const Spacer(),
            const Text('Settings', style: AppTextStyles.titleBold),
            const Spacer(),
          ],
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Save',
          onPressed: (canSave && !loading) ? () => onSave() : null,
          isLoading: loading,
          textStyle: AppTextStyles.footerMedium.copyWith(color: AppColors.nineHundred),
          fullWidth: false,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
