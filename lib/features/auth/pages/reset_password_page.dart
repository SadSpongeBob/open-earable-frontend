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
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../../app/widgets/user_card.dart';
import '../../../app/widgets/input_box.dart';
import '../../../app/ui/popup_toast.dart';

/// Page that allows a user to reset their password using an authentication token.
///
/// This page is accessed after a password reset request. Users can enter a new
/// password and submit it. Successful reset shows a confirmation dialog and
/// redirects the user to the login page. Failures are displayed via toast messages.
/// 
/// Parameters:
/// - [authToken]: The authentication token used to authorize the password reset request.
class ResetPasswordPage extends ConsumerStatefulWidget {
  final String authToken;

  const ResetPasswordPage({super.key, required this.authToken});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetState();
}

class _ResetState extends ConsumerState<ResetPasswordPage> {
  // --- Form Controller ---
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- UI State ---
  bool _loading = false;
  bool _showPassword = false;

  /// Returns true if the password field is not empty.
  bool get _isFormFilled => _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pwController.addListener(_onFormChanged);
  }

  /// Updates the UI whenever the password input changes.
  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _pwController.dispose();
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
                    "Reset Password",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleBold,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Enter a new password.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textRegular,
                  ),

                  const SizedBox(height: 30),

                  // Password input field
                  InputBox(
                    controller: _pwController,
                    hint: "Password",
                    validator: Validators.password,
                    obscureText: !_showPassword,
                    suffixIcon: Transform.translate(
                      offset: const Offset(-8, 0),
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

                  const SizedBox(height: 30),

                  // Reset password button
                  AppButton.primary(
                    text: "Reset",
                    onPressed: _isFormFilled ? _handleReset : null,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the password reset submission.
  ///
  /// Validates the password field, calls the [authServiceProvider] to update
  /// the password using the provided auth token, and shows a confirmation dialog
  /// on success. If failes then displays an error toast message.
  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await ref
          .read(authServiceProvider)
          .updatePassword(
            password: _pwController.text,
            authToken: widget.authToken,
          );

      if (!mounted) return;

      setState(() => _loading = false);

      await AppAlertDialog.show(
        context,
        title: 'Password Reset',
        message: 'Your password has been reset successfully',
      );

      if (!mounted) return;
      context.go(Routes.login);
    } on DioException catch (exception) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).state =
          ToastEvent.error(exception.message ?? 'Request failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
