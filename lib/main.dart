import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/constants/colors.dart';
import 'features/auth/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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

      home: const LoginPage(),
    );
  }
}
