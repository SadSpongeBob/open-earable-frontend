import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routing/routes.dart';
import '../../../app/theme/text_styles.dart';
import '../../settings/widgets/download_method_dropdown.dart';
import '../../auth/widgets/auth_card.dart';
import '../widgets/settings_app_bar.dart';

class GuestSettingsPage extends StatefulWidget {
  const GuestSettingsPage({super.key});

  @override
  State<GuestSettingsPage> createState() => _GuestSettingsPageState();
}

class _GuestSettingsPageState extends State<GuestSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingsAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/app_logo.png', width: 92, height: 110),
                  const SizedBox(height: 8),
                  const Text(
                    'Guest Account',
                    textAlign: TextAlign.center,
                    style: AuthTextStyles.title,
                  ),

                  const SizedBox(height: 15),
                  const CustomDropdown(),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: AuthTextStyles.body,
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.login),
                        child: Text("Log in", style: AuthTextStyles.link),
                      ),
                    ],
                  ),

                  Row(
                    children: const [
                      SizedBox(width: 50),
                      Expanded(child: Divider(thickness: 2, color: Colors.black)),
                      SizedBox(width: 9),
                      Text("or", style: AuthTextStyles.body),
                      SizedBox(width: 9),
                      Expanded(child: Divider(thickness: 2, color: Colors.black)),
                      SizedBox(width: 50),
                    ],
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account yet? ",
                        style: AuthTextStyles.body,
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.signup),
                        child: Text("Sign Up", style: AuthTextStyles.link),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

      ),
    );
  }

  Future<void> _handleChanges() async {
    // TODO: handle saving changes to user account
  }
}
