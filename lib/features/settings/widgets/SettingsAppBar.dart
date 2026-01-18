import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';
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
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.15 * 255).round()),
                blurRadius: 12,
              ),
            ],
          ),
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
                    style: TextStyle(
                      color: Color(0xFFFF4442),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                const Spacer(),

                const Text(
                  'Settings',
                  style: GlobalTextStyles.appBarTitle,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Save logic
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
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
