import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import '../../../app/theme/text_styles.dart';

import '../../auth/widgets/auth_card.dart';

import '../../auth/widgets/text_field.dart';


class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _namecontroller = TextEditingController();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
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

    /// BACK TO PORTRAIT
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

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
                  color: Colors.black,
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),

                const Spacer(),

                /// Title
                const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                /// Save
                TextButton(
                  onPressed: () {
                    // Save logic
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

        ),
      ),


      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
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
                    "Account",
                    textAlign: TextAlign.center,
                    style: AuthTextStyles.title,
                  ),
                  Image.asset('assets/images/user.png',
                      width: 80, height: 100),
                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _namecontroller,
                    hint: "kuzey der Törke",
                    validator: Validators.name,
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _emailController,
                    hint: "mehdizzou@gamil.com",
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 10),

                  AuthTextField(
                    controller: _pwController,
                    hint: ".............",
                    validator: Validators.password,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const CustomDropdown(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          //return to login page
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

                ],
              ),
            ),
          ),
        ),

      ),
    );
  }

}
class CustomDropdown extends StatefulWidget {
  const CustomDropdown({super.key});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String _selected = "Download with WiFi";

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1F1F1F), width: 3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: Text('$_selected')),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: (value) => setState(() => _selected = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: "Download with WiFi", child: Text('Download with WiFi', style: TextStyle(color: _getColor("Download with WiFi", _selected)))),

              PopupMenuItem(value: 'Download with mobile data and WiFi', child: Text('Download with mobile data and WiFi',style: TextStyle(color: _getColor("Download with mobile data and WiFi", _selected)))),

            ],
          ),
        ],
      ),
    );
  }
  Color _getColor(String value, String selected) {
    if (value == selected) {
      return Colors.red;
    }
    return Colors.black;
  }
}
