import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/features/auth/state/session_provider.dart';

import '../../../app/theme/text_styles.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../../app/widgets/user_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_seperator.dart';
import '../../../app/widgets/input_box.dart';

/// Login page for OpenEarable app.
///
/// Allows users to log in with email and password, reset their password,
/// or continue as a guest. Utilizes Riverpod providers to handle
/// authentication state and toast notifications.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // --- Form Controllers ---
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- UI State ---
  bool _showPassword = false;

  /// Returns true if both email and password fields are filled.
  bool get _isFormFilled =>
      _emailController.text.isNotEmpty && _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
    _pwController.addListener(_onFormChanged);
  }

  /// Triggered when form fields change to update UI state.
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

    /// Listens for [ToastEvent] updates to show non-blocking feedback to the user.
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;
      PopupToast.show(context, message: next.message);
      ref.read(toastProvider.notifier).state = null;
    });

    /// Listens for [AuthState] updates to show auth error messages as toast.
    ref.listen<AuthState>(sessionProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty && msg != prev?.error) {
        ref.read(toastProvider.notifier).state = ToastEvent.error(msg);
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
        child: SafeArea(
          child: UserCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 90,
                    height: 110,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Log into\nyour account",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleBold,
                  ),

                  const SizedBox(height: 35),

                  // Email Input
                  InputBox(
                    controller: _emailController,
                    hint: "Email Address",
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  InputBox(
                    controller: _pwController,
                    hint: "Password",
                    validator: Validators.password,
                    obscureText: !_showPassword,
                    suffixIcon: Transform.translate(
                      offset: const Offset(-20, 0),
                      child: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  _buildRememberForgotRow(context),
                  const SizedBox(height: 20),

                  // Login Button
                  AppButton.primary(
                    text: "Log In",
                    onPressed: _isFormFilled ? _handleLogin : null,
                    isLoading: loading,
                  ),

                  const SizedBox(height: 10),

                  // Signup Link
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible( // <-- makes Text respect available width
                        child: Text(
                          "Don’t have an account yet? ",
                          style: AppTextStyles.footerRegular,
                          softWrap: true,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.signup),
                        child: Text("Sign Up", style: AppTextStyles.footerBold),
                      ),
                    ],
                  ),

                  const AuthSeparator(),

                  // Guest Login
                  AuthFooterLink(
                    text: "Continue as Guest",
                    bold: true,
                    onTap: () async {
                      await ref.read(authControllerProvider).guestLogin();
                      if (!context.mounted) return;
                      context.go(Routes.home);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the "Forgot Password?" row.
  Widget _buildRememberForgotRow(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: () => context.go(Routes.requestResetPassword),
          child: Text("Forgot Password?", style: AppTextStyles.footerRegular),
        ),
      ],
    );
  }

  /// Handles login form submission
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
