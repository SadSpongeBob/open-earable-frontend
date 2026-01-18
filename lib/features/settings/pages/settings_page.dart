import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import '../../../app/theme/text_styles.dart';
import '../../settings/widgets/download_method_dropdown.dart';
import '../../auth/widgets/auth_card.dart';
import '../../auth/widgets/text_field.dart';
import '../widgets/SettingsAppBar.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsState();
}
class _SettingsState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingsAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Account',
                    textAlign: TextAlign.center,
                    style: GlobalTextStyles.cardTitle,
                  ),
                  Image.asset('assets/images/user.png', width: 80, height: 100),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _nameController,
                    //TODO: fetch current user name
                    hint: 'current user name',
                    validator: Validators.name,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _emailController,
                    //TODO: fetch current user email
                    hint: 'current user email',
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _pwController,
                    //TODO: fetch current user password
                    hint: "current user password",
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
                  const CustomDropdown(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // return to login page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Sign Out', style: TextStyle(
                              color: Color(0xFF1F1F1F),
                              fontSize: 16,
                              fontFamily: 'Roboto'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Delete account logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ),
    );
  }
  Future<void> _handleChanges() async {
    //to do: handle saving changes to user account
  }

}


