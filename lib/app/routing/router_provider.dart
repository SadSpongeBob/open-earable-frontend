import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/routing/refresh_stream.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/features/auth/pages/request_reset_password_page.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:openearable/features/auth/pages/signup_page.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/recordings/pages/recordings_page.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';
import 'package:openearable/features/sensors/pages/sensor_page.dart';
import 'package:openearable/app/utils/helpers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(
    ref.read(sessionProvider.notifier).stream,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: refresh,

    routes: [
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];

          if (token == null || token.isEmpty) {
            return const RequestResetPage();
          }

          return ResetPasswordPage(authToken: token);
        },
      ),

      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: Routes.recording,
        builder: (_, _) => const RecordingPage(),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(
        path: Routes.requestResetPassword,
        builder: (_, _) => const RequestResetPage(),
      ),
      GoRoute(
        path: Routes.sensordata, 
        builder: (context, state) {
          final isRecordingSource = state.uri.queryParameters['source'] == 'recording';
          
          return SensorPage(
            isRecordingSource: isRecordingSource,
            onBluetoothPressed: () {
              showDevicesPopup(
                context: context,
                isSensorPage: true,
              );
            },
          );
        },
      ),
    ],

    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;

      if (kDebugMode) {
        debugPrint(
          'redirect | loc=$loc '
              'path=${state.uri.path} '
              'loggedOut=${session.isLoggedOut}',
        );
      }


      final isPublic =
          loc == Routes.login ||
          loc == Routes.signup ||
          loc == Routes.requestResetPassword ||
          loc == Routes.resetPassword;

      if (session.isLoading) return null;

      if (session.isLoggedOut) {
        return isPublic ? null : Routes.login;
      }

      if (loc == Routes.login || loc == Routes.signup) {
        return Routes.home;
      }

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Routing error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No route for: ${state.uri}\n\n${state.error ?? ""}'),
      ),
    ),
  );
});
