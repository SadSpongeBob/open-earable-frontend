import 'package:flutter/material.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/features/auth/pages/signup_page.dart';
import 'package:openearable/app/widgets/primary_button.dart';
import 'package:openearable/utils/validators.dart';
import 'package:openearable/features/home/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth * 0.85 > 420 ? 420 : screenWidth * 0.85;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFCA4C63),
              Color(0xFF844252),
              Color(0xFFF0D9EA),
              Color(0xFF5B3B63),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo
          Image.asset('assets/images/app_logo.png', width: 85, height: 85),

          const SizedBox(height: 18),
          const Text(
            'Log into\nyour account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24),
          _buildEmailField(),

          const SizedBox(height: 14),
          _buildPasswordField(),

          const SizedBox(height: 10),
          _buildRememberForgot(),

          const SizedBox(height: 20),
          _loading
              ? const CircularProgressIndicator()
              : PrimaryButton(
            text: 'Log In',
            onPressed: _handleLogin,
          ),

          const SizedBox(height: 16),
          _buildSignupText(),

          const SizedBox(height: 12),
          _buildSeparator(),

          const SizedBox(height: 12),
          _buildGuestLogin(),
        ],
      ),
    );
  }

  // ----------------------------
  // EMAIL FIELD
  // ----------------------------

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: Validators.email,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration("Email Address"),
    );
  }

  // ----------------------------
  // PASSWORD FIELD
  // ----------------------------

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _pwController,
      validator: Validators.password,
      obscureText: !_showPassword,
      decoration: _inputDecoration("Password").copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide:
        BorderSide(color: Colors.black, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide:
        BorderSide(color: Colors.black, width: 1.4),
      ),
    );
  }

  // ----------------------------
  // REMEMBER + FORGOT
  // ----------------------------

  Widget _buildRememberForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v ?? false),
        ),
        const Text("Remember me"),

        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text("Forgot Password?"),
        ),
      ],
    );
  }

  // ----------------------------
  // SIGN UP LINK
  // ----------------------------

  Widget _buildSignupText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account yet? "),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // SEPARATOR (------ or ------)
  // ----------------------------

  Widget _buildSeparator() {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1, color: Colors.black)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("or"),
        ),
        Expanded(child: Divider(thickness: 1, color: Colors.black)),
      ],
    );
  }

  // ----------------------------
  // CONTINUE AS GUEST
  // ----------------------------

  Widget _buildGuestLogin() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      child: const Text(
        "Continue as Guest",
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ----------------------------
  // LOGIN HANDLER
  // ----------------------------

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final result = await AuthService().login(
      _emailController.text.trim(),
      _pwController.text.trim(),
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Login failed')),
      );
    }
  }
}
