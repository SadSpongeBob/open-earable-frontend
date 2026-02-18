import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/routing/refresh_stream.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/features/auth/pages/request_reset_password_page.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:openearable/features/auth/pages/signup_page.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/playback/pages/sensor_playback_page.dart';
import 'package:openearable/api/models/recording/sensor.dart' as custom_sensor;
import 'package:openearable/features/recordings/pages/recordings_page.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';
import 'package:openearable/features/sensors/pages/sensor_page.dart';
import 'package:openearable/features/sensors/pages/sensor_details_page.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/features/playback/pages/playback_page.dart';

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
      GoRoute(path: Routes.recording, builder: (_, _) => const RecordingPage()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(
        path: Routes.requestResetPassword,
        builder: (_, _) => const RequestResetPage(),
      ),
      GoRoute(
        path: '${Routes.playbackBase}/:source/:id',
        builder: (context, state) {
          final sourceStr = state.pathParameters['source']!;
          final id = state.pathParameters['id']!;

          final rec = state.extra as Recording?;
          final source = sourceStr == 'cloud'
              ? RecordingSource.cloud
              : RecordingSource.local;

          return PlaybackPage(recordingId: id, source: source, recording: rec);
        },
      ),
      GoRoute(path: Routes.sensorPlayback, builder: (context, state) {
        final sensor = state.extra as custom_sensor.Sensor;

        return SensorPlaybackPage(sensor: sensor);
      }),
      GoRoute(
        path: Routes.sensordata,
        builder: (context, state) {
          final isRecordingSource =
              state.uri.queryParameters['source'] == 'recording';
          return SensorPage(isRecordingSource: isRecordingSource);
        },
      ),
      GoRoute(
        path: Routes.sensordataDetails,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;

          if (data == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  "Sensor data are missing. Please go back.",
                  style: AppTextStyles.subheaderRegular,
                ),
              ),
            );
          }

          return SensorDetailsPage(
            sensor: data['sensor'] as Sensor,
            wearable: data['wearable'] as Wearable,
            sensorIndex: data['sensorIndex'] as int,
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
  );
});
