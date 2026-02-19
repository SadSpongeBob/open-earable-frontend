import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/routing//router_provider.dart';
import 'package:openearable/app/routing/app_bootstrapper.dart';

/// Entry point for the OpenEarable application.
///
/// Initializes required resources, environment variables, and sets
/// device orientation to landscape. Prepares local media and starts
/// the app with [ProviderScope] for Riverpod state management.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Force landscape orientation before the app starts.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final localMedia = await LocalMedia.initLocalMedia();

  runApp(
    ProviderScope(
      overrides: [localMediaProvider.overrideWithValue(localMedia)],
      child: const OpenEarableApp(),
    ),
  );
}

/// Root widget of the OpenEarable application.
///
/// Uses [MaterialApp.router] to provide navigation via GoRouter.
/// Wraps the child widgets with [AppBootstrapper] to handle
/// app-wide initialization and startup logic.
class OpenEarableApp extends ConsumerWidget {
  const OpenEarableApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'OpenEarable',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.fifty,
      ),
      routerConfig: router,
      builder: (context, child) {
        return Stack(children: [child!, const AppBootstrapper()]);
      },

    );
  }
}
