import 'package:flutter/material.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/app/utils/validators.dart';
import '../../../app/theme/text_styles.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_seperator.dart';
import '../widgets/text_field.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _namecontroller = TextEditingController();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPassword = false;

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

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _namecontroller.dispose();
    _emailController.dispose();
    _pwController.dispose();
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
                  "Create your account",
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.title,
                ),

                const SizedBox(height: 35),

                AuthTextField(
                  controller: _namecontroller,
                  hint: "Name",
                  validator: Validators.name,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 20),

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

                const SizedBox(height: 35),

                AuthButton(
                  text: "Sign up",
                  loading: _loading,
                  enabled: _isFormFilled,
                  onTap: _handleSingup,
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: AuthTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Text(
                        "Log in",
                        style: AuthTextStyles.link,
                      ),
                    ),
                  ],
                ),

                const AuthSeparator(),

                AuthFooterLink(
                  text: "Continue as Guest",
                  bold: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _handleSingup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final result = await AuthService().signup(
      _namecontroller.text.trim(),
      _emailController.text.trim(),
      _pwController.text.trim(),

    );

    setState(() => _loading = false);

    if (!mounted) return;
    print(result) ;
    //result.success
    if (true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }
}
