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
import '../../../app/widgets/user_card.dart';
import '../../../app/widgets/input_box.dart';

class RequestResetPage extends ConsumerStatefulWidget {
  const RequestResetPage({super.key});

  @override
  ConsumerState<RequestResetPage> createState() => _RequestResetState();
}

class _RequestResetState extends ConsumerState<RequestResetPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  bool get _isFormFilled => _emailController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
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

                  InputBox(
                    controller: _emailController,
                    hint: "Email Address",
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 30),

                  AppButton.primary(
                    text: "Send",
                    onPressed: _isFormFilled ? _handleSendReset : null,
                    isLoading: _loading,
                  ),

                  const SizedBox(height: 16),

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Request failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
