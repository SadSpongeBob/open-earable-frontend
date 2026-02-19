import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/alert_dialog.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../../app/widgets/user_card.dart';
import '../../../app/widgets/input_box.dart';

/// Page for requesting a password reset.
///
/// Allows users to input their registered email address to receive a
/// password reset link. Provides feedback via toast notifications and
/// confirmation dialogs. Integrates with the authentication service.
class RequestResetPage extends ConsumerStatefulWidget {
  const RequestResetPage({super.key});

  @override
  ConsumerState<RequestResetPage> createState() => _RequestResetState();
}

class _RequestResetState extends ConsumerState<RequestResetPage> {
  // --- Form Controllers ---
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- UI State ---
  bool _loading = false;

  /// Returns true if the email input field is not empty.
  bool get _isFormFilled => _emailController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
  }

  /// Updates the UI whenever the form changes.
  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Listens for [ToastEvent] updates to show non-blocking feedback to the user.
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;
      PopupToast.show(context, message: next.message);
      ref.read(toastProvider.notifier).state = null;
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
                    "Forgot your password?",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleBold,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Enter your Email so that we can send you password reset link.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textRegular,
                  ),

                  const SizedBox(height: 35),
                  
                  // Email input field
                  InputBox(
                    controller: _emailController,
                    hint: "Email Address",
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 30),

                  // Send reset link button
                  AppButton.primary(
                    text: "Send",
                    onPressed: _isFormFilled ? _handleSendReset : null,
                    isLoading: _loading,
                  ),

                  const SizedBox(height: 16),

                  // Navigate back to login page
                  AppButton.secondary(
                    text: "Back to Log In",
                    onPressed: () => context.go(Routes.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the password reset request.
  ///
  /// Validates the email form, sends a reset request via [authServiceProvider],
  /// shows a confirmation dialog on success, and displays a toast on failure.
  Future<void> _handleSendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();

    try {
      await ref.read(authServiceProvider).resetPassword(emailAddress: email);

      if (!mounted) return;

      await AppAlertDialog.show(
        context,
        title: 'Reset request',
        message: 'Password reset link has been sent to your email address!',
      );

      if (!mounted) return;

      context.go(Routes.login);
    } on DioException catch (e) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).state =
          ToastEvent.error(e.message ?? 'Request failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
