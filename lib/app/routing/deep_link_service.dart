import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/routing/routes.dart';

/// Service responsible for handling incoming deep links and routing
/// users to the appropriate screen.
///
/// Supports:
/// - Initial app launch links (cold start)
/// - Runtime deep links via stream
class DeepLinkService {
  /// Subscription to the deep link stream for runtime link handling.
  StreamSubscription<Uri>? _linkSub;

  /// Instance of AppLinks used to fetch initial and ongoing deep links.
  final AppLinks _appLinks = AppLinks();

  /// Initializes deep link handling.
  ///
  /// - Processes the initial deep link if the app was launched via a link
  /// - Subscribes to the deep link stream for links received while the app is running
  ///
  /// Requires a [GoRouter] instance to perform navigation based on the URI.
  Future<void> init(GoRouter router) async {
    final initial = await _appLinks.getInitialLink();
    _handleIncomingUri(router, initial);

    await _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingUri(router, uri),
      onError: (err) {
        if (kDebugMode) print('Deep link stream error: $err');
      },
    );
  }

  /// Cancels the deep link stream subscription to prevent memory leaks.
  void dispose() => _linkSub?.cancel();

  /// Handles incoming URIs and performs navigation if they match
  /// supported deep link patterns.
  ///
  /// Currently supports:
  /// - Password reset links with a token query parameter
  ///
  /// Navigation is deferred to the next frame to ensure safe router usage.
  void _handleIncomingUri(GoRouter router, Uri? uri) {
    if (uri == null) return;

    final isResetLink =
        uri.scheme == 'open-earable' && uri.host == 'app' &&
            uri.path == Routes.resetPassword;
    if (!isResetLink) return;

    final token = uri.queryParameters['token'];
    if (kDebugMode) {
      debugPrint('DeepLink received: $uri');
      debugPrint('Parsed token: $token');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (token == null || token.isEmpty) {
        router.go(Routes.requestResetPassword);
      } else {
        router.go(
            '${Routes.resetPassword}?token=${Uri.encodeComponent(token)}');
      }
    });
  }
}

/// Riverpod provider for [DeepLinkService].
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final svc = DeepLinkService();
  ref.onDispose(svc.dispose);
  return svc;
});
