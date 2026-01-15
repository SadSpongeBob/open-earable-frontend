import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/features/playback/pages/Playback.dart';
import '../../../app/theme/text_styles.dart';
import '../../settings/widgets/downloadMethod_customDropDown.dart';
import '../../auth/widgets/auth_card.dart';

import '../../auth/widgets/text_field.dart';


class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();

    /// FORCE LANDSCAPE
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Dispose controllers and restore orientation
    _nameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
   
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.15 * 255).round()),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaybackPage()),
                      );
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // Save
                  TextButton(
                    onPressed: () {
                      // Save logic
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

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
                    style: AuthTextStyles.title,
                  ),
                  Image.asset('assets/images/user.png', width: 80, height: 100),
                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _nameController,
                    //to do: fetch current user name
                    hint: '',
                    validator: Validators.name,
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _emailController,
                    //to do: fetch current user email
                    hint: '',
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _pwController,
                    //to do: fetch current user password
                    hint: '',
                    validator: Validators.password,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const CustomDropdown(),
                  const SizedBox(height: 10),

                  // Button row with horizontal padding
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
                          child: const Text('Sign Out'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            // Delete account logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.white),
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



