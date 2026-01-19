import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openearable/app/theme/appBar_styles.dart';
import '../../auth/pages/login_page.dart';

class SettingsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SettingsAppBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(70);
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: SafeArea(
        child: Container(
          height: 100,
          decoration: GlobalAppBarStyles.appBarDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: GlobalAppBarStyles.appBarText,
                  ),
                ),

                const Spacer(),

                const Text(
                  'Settings',
                  style: GlobalAppBarStyles.appBarTitle,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Save logic
                  },
                  child: const Text(
                    'Save',
                    style: GlobalAppBarStyles.appBarText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
