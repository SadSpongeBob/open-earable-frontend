import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';

enum NetworkStatus {
  wifi,
  mobile,
  offline;

  factory NetworkStatus.mapResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => NetworkStatus.wifi,
      ConnectivityResult.mobile => NetworkStatus.mobile,
      _ => NetworkStatus.offline,
    };
  }

  bool shouldUpload(bool isWifiOnly) {
    return switch (this) {
      wifi => true,
      mobile => !isWifiOnly,
      offline => false,
    };
  }

  bool get isOffline => this == offline;
}

Future<T> waitForFirstData<T>(
  Ref ref,
  ProviderListenable<AsyncValue<T>> provider, {
  bool useCache = true,
  Duration? timeout,
}) {
  if (useCache) {
    final current = ref.read(provider);
    final cached = current.asData?.value;
    if (cached != null) return Future.value(cached);
  }

  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> sub;

  sub = ref.listen<AsyncValue<T>>(provider, (prev, next) {
    final v = next.asData?.value;
    if (v != null && !completer.isCompleted) {
      completer.complete(v);
      sub.close();
      return;
    }

    if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace);
      sub.close();
    }
  });

  Future<T> future = completer.future;

  if (timeout != null) {
    future = future.timeout(
      timeout,
      onTimeout: () {
        sub.close();
        throw TimeoutException('Timed out waiting for provider data');
      },
    );
  }

  return future;
}

final networkRefreshTriggerProvider = StateProvider<int>((_) => 0);

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  ref.watch(networkRefreshTriggerProvider);

  final initial = await Connectivity().checkConnectivity();
  yield NetworkStatus.mapResult(initial);

  await for (final result in Connectivity().onConnectivityChanged) {
    yield NetworkStatus.mapResult(result);
  }
});
