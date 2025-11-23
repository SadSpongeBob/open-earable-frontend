import 'package:flutter/material.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/app/constants/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OpenEarableApp());
}

class OpenEarableApp extends StatelessWidget {
  const OpenEarableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenEarable',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "Roboto",
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),

      //home: const LoginPage(),
    );
  }
}
