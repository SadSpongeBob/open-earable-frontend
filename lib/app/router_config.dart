import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/routes.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:uni_links/uni_links.dart';

class RouterConfig {
  RouterConfig() {
    router = _buildRouter();
  }

  late final GoRouter router;
  StreamSubscription<Uri?>? _linkSub;

  GoRouter getRouter() => router;

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: Routes.resetPassword,
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'];
            return ResetPasswordPage(authToken: token);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Routing error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No route for: ${state.uri}\n\n${state.error ?? ""}'),
        ),
      ),

      // TODO: later add redirect/auth-guard
      // redirect: (context, state) { ... return null; },
    );
  }

  Future<void> initDeepLinks() async {
    try {
      // Cold start (app opened from link)
      final initial = await getInitialUri();
      _handleIncomingUri(initial);

      // Warm start (app already open)
      await _linkSub?.cancel();
      _linkSub = uriLinkStream.listen(
        _handleIncomingUri,
        onError: (err) {
          // TODO: add logging
          if (kDebugMode) {
            print('Deep link stream error: $err');
          }
        },
      );
    } catch (e) {
      // TODO: add logging
      if (kDebugMode) {
        print('initDeepLinks exception: $e');
      }
    }
  }

  void dispose() {
    _linkSub?.cancel();
  }

  void _handleIncomingUri(Uri? uri) {
    if (uri == null) return;

    // Custom scheme format:
    // open-earable://reset-password?token=authToken
    final isResetLink =
        uri.scheme == 'open-earable' && uri.host == 'reset-password';

    if (!isResetLink) {
      return;
    }

    final token = uri.queryParameters['token'];

    final target = (token == null || token.isEmpty)
        ? Routes.resetPassword
        : '${Routes.resetPassword}?token=${Uri.encodeComponent(token)}';

    router.go(target);
  }
}
