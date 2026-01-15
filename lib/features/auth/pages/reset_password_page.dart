import 'package:flutter/material.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/app/utils/validators.dart';

import '../../../app/theme/text_styles.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? authToken;
  const ResetPasswordPage({super.key, this.authToken});

  @override
  State<ResetPasswordPage> createState() => _ResetState();
}

class _ResetState extends State<ResetPasswordPage> {
  final _pwController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPassword = false;

  bool get _isFormFilled => _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pwController.addListener(_onFormChanged);
    _confirmController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _pwController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/app_logo.png', width: 90, height: 110),
                const SizedBox(height: 20),

                const Text(
                  "Reset Password",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.title,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter a new password.",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.body,
                ),

                const SizedBox(height: 30),

                AuthTextField(
                  controller: _pwController,
                  hint: "Password",
                  validator: Validators.password,
                  obscureText: !_showPassword,
                  suffixIcon: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                AuthButton(
                  text: "Reset",
                  loading: _loading,
                  enabled: _isFormFilled,
                  onTap: _handleReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    // TODO: Replace this with a real API call
    // something like : AuthService().resetPassword(widget.authToken, _pwController.text)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Reset'),
        content: const Text('Your password has been reset successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
