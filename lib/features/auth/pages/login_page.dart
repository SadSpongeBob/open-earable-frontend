import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/features/auth/state/session_provider.dart';

import '../../../app/theme/text_styles.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_seperator.dart';
import '../widgets/text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;

  bool get _isFormFilled =>
      _emailController.text.isNotEmpty && _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
    _pwController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final loading = session.isLoading;

    ref.listen<AuthState>(sessionProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty && msg != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

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
                  "Log into\nyour account",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.title,
                ),

                const SizedBox(height: 35),

                AuthTextField(
                  controller: _emailController,
                  hint: "Email Address",
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                AuthTextField(
                  controller: _pwController,
                  hint: "Password",
                  validator: Validators.password,
                  obscureText: !_showPassword,
                  suffixIcon: Transform.translate(
                    offset: const Offset(-20, 0),
                    child: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                _buildRememberForgotRow(context),
                const SizedBox(height: 35),

                AuthButton(
                  text: "Log In",
                  loading: loading,
                  enabled: _isFormFilled && !loading,
                  onTap: () => _handleLogin(),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t have an account yet? ",
                      style: AuthTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: () => context.go(Routes.signup),
                      child: Text("Sign Up", style: AuthTextStyles.link),
                    ),
                  ],
                ),

                const AuthSeparator(),

                AuthFooterLink(
                  text: "Continue as Guest",
                  bold: true,
                  onTap: () async {
                    await ref.read(authControllerProvider).guestLogin();
                    context.go(Routes.home);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: () => context.go(Routes.requestResetPassword),
          child: Text("Forgot Password?", style: AuthTextStyles.body),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider)
        .login(
          email: _emailController.text.trim(),
          password: _pwController.text.trim(),
        );
  }
}
