import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';

/// AppBar widget for the Settings page.
///
/// Displays a 'Back' button on the left that navigates to the previous page,
/// a centered 'Settings' title, and a 'Save' button on the right. 
/// The 'Save' button can show a loading state and is enabled only when 
/// [canSave] is true and [loading] is false.
///
/// Implements [PreferredSizeWidget] to allow AppBar integration with Scaffold.
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  
  /// Indicates whether a save operation is currently in progress.
  final bool loading;

  /// Determines if the 'Save' button should be enabled.
  final bool canSave;

  /// Callback invoked when the 'Back' button is pressed.
  final VoidCallback onBack;

  /// Async callback invoked when the 'Save' button is pressed.
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
