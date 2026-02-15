import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/utils/validators.dart';

import '../../../app/theme/text_styles.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/text_field.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String authToken;

  const ResetPasswordPage({super.key, required this.authToken});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetState();
}

class _ResetState extends ConsumerState<ResetPasswordPage> {
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPassword = false;

  bool get _isFormFilled => _pwController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pwController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                AuthButton(
                  text: "Reset",
                  loading: _loading,
                  enabled: _isFormFilled && !_loading,
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

    try {
      await ref
          .read(authServiceProvider)
          .updatePassword(
            password: _pwController.text,
            authToken: widget.authToken,
          );

      if (!mounted) return;

      ref.read(toastProvider.notifier).state =
      const ToastEvent.success('Password reset successfully');

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
