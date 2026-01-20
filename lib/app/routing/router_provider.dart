import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/routing/refresh_stream.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/recordings/pages/recordings_page.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  final refresh = GoRouterRefreshStream(
    ref.watch(authControllerProvider.notifier).stream,
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
          return ResetPasswordPage(authToken: token);
        },
      ),

      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: Routes.recording,
        builder: (_, _) => const RecordingPage(),
      ),
      // GoRoute(path: Routes.playback, builder: (_, __) => const PlaybackPage()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
      // GoRoute(path: Routes.export, builder: (_, __) => const ExportPage()),
      // GoRoute(
      //   path: Routes.sensordata,
      //   builder: (_, __) => const SensorDataPage(),
      // ),
    ],

    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      final isPublic =
          loc == Routes.login ||
          loc == Routes.signup ||
          loc == Routes.resetPassword;

      if (auth.isLoading) return null;

      if (auth.isLoggedOut) {
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
