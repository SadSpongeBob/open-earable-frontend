import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/routing/routes.dart';

class DeepLinkService {
  StreamSubscription<Uri>? _linkSub;
  final AppLinks _appLinks = AppLinks();

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

  void dispose() => _linkSub?.cancel();

  void _handleIncomingUri(GoRouter router, Uri? uri) {
    if (uri == null) return;

    final isResetLink =
        uri.scheme == 'open-earable' && uri.host == 'reset-password';
    if (!isResetLink) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      router.go(Routes.requestResetPassword);
    } else {
      router.go(
        '${Routes.resetPassword}?token=${Uri.encodeComponent(token)}',
      );
    }
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final svc = DeepLinkService();
  ref.onDispose(svc.dispose);
  return svc;
});
