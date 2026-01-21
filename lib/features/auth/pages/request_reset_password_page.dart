import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/utils/validators.dart';
import '../../../app/theme/text_styles.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/text_field.dart';

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
        child: AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/app_logo.png', width: 90, height: 110),
                const SizedBox(height: 20),

                const Text(
                  "Forgot your password?",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.title,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter your Email so that we can send you password reset link.",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.body,
                ),

                const SizedBox(height: 35),

                AuthTextField(
                  controller: _emailController,
                  hint: "Email Address",
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 30),

                AuthButton(
                  text: "Send",
                  loading: _loading,
                  enabled: _isFormFilled && !_loading,
                  onTap: _handleSendReset,
                ),

                const SizedBox(height: 25),

                AuthFooterLink(
                  text: "< Back to Log In",
                  onTap: () => context.go(Routes.login),
                ),
              ],
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

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset Link Sent'),
          content: Text(
            'If an account with $email exists, a password reset link has been sent to that address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
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
