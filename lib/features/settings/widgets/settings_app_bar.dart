import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/theme/app_bar_styles.dart';

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
      flexibleSpace: Container(decoration: GlobalAppBarStyles.appBarDecoration),
      titleSpacing: 0,
      title: Row(
        children: [
          TextButton(
            onPressed: onBack,
            child: const Text(
              'Back',
              style: GlobalAppBarStyles.appBarSecondaryText,
            ),
          ),
          const Spacer(),
          const Text('Settings', style: GlobalAppBarStyles.appBarTitle),
          const Spacer(),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: (canSave && !loading) ? () => onSave() : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Save',
                  style: (canSave
                      ? GlobalAppBarStyles.appBarMainText
                      : GlobalAppBarStyles.appBarInactiveText),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
