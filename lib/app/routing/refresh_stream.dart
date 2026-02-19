import 'dart:async';

import 'package:flutter/cupertino.dart';

/// A [ChangeNotifier] that listens to a [Stream] and notifies listeners
/// whenever a new event is emitted.
///
/// Commonly used with GoRouter's `refreshListenable` to trigger router
/// refreshes based on external stream updates.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
