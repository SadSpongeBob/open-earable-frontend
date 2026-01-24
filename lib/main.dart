import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/app/utils/logger.dart';
import 'package:provider/provider.dart';
import 'app/constants/colors.dart';
import 'package:logger/logger.dart';
import 'package:openearable/api/models/device/wearable_connector.dart';
import 'package:openearable/features/home/controllers/wearables_provider.dart';
import 'package:openearable/features/home/controllers/sensor_recorder_provider.dart';
import 'package:openearable/features/home/controllers/recording_chart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Adding a timeout to see if the app works. The App doesn't run for me without 
    // it, because it's unable to see the env file, crazy
    await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 2));
  } catch (e) {
    print("Dotenv failed to load, using system defaults: $e");
  }
  initLogger(Logger());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WearablesProvider(), lazy: true),
        Provider.value(value: WearableConnector()),
        ChangeNotifierProvider(
          create: (context) => SensorRecorderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordingChartProvider(),
        ),
      ],
      child: const OpenEarableApp()
    ),
  );
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

      home: HomePage(),
    );
  }
}
