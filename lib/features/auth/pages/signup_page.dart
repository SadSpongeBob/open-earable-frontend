import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/app/utils/validators.dart';

import '../../../app/theme/text_styles.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../../app/widgets/user_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_seperator.dart';
import '../../../app/widgets/input_box.dart';

/// Sign Up Page that allows users to create a new account in the app.
///
/// Users provide a name, email, and password. Upon successful signup, the user
/// is logged in automatically via [authControllerProvider]. The page also
/// allows users to navigate to the login page or continue as a guest.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  // --- Form Controllers ---
  final _namecontroller = TextEditingController();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- UI State ---
  bool _showPassword = false;

  /// Returns true if all input fields (name, email, password) are not empty.
  bool get _isFormFilled =>
      _namecontroller.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _namecontroller.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _pwController.addListener(_onFormChanged);
  }

  /// Updates the UI whenever a form field changes.
  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _namecontroller.dispose();
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
                    "Create your account",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleBold,
                  ),

                  const SizedBox(height: 35),

                  // Name input
                  InputBox(
                    controller: _namecontroller,
                    hint: "Name",
                    validator: Validators.name,
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 20),

                  // Email input
                  InputBox(
                    controller: _emailController,
                    hint: "Email Address",
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // Password input
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

                  const SizedBox(height: 20),

                  // Sign up button
                  AppButton.primary(
                    text: "Sign Up",
                    onPressed: _isFormFilled ? _handleSignup : null,
                    isLoading: loading,
                  ),

                  const SizedBox(height: 10),

                  // Link to login page
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Already have an account? ",
                          style: AppTextStyles.footerRegular,
                          softWrap: true,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.login),
                        child: Text("Log in", style: AppTextStyles.footerBold),
                      ),
                    ],
                  ),

                  const AuthSeparator(),

                  // Continue as guest
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

  /// Handles the signup process by validating the form and calling the
  /// [authControllerProvider.signup] method.
  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider)
        .signup(
          name: _namecontroller.text.trim(),
          email: _emailController.text.trim(),
          password: _pwController.text.trim(),
        );
  }
}
