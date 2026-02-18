import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';

/// Represents the current network connectivity status.
///
/// - `wifi`: Device is connected via Wi-Fi.
/// - `mobile`: Device is connected via cellular/mobile data.
/// - `offline`: Device has no network connection.
///
/// Provides helper methods:
/// - `mapResult(ConnectivityResult)`: Converts a [ConnectivityResult] to [NetworkStatus].
/// - `shouldUpload(bool isWifiOnly)`: Determines whether uploads should occur based on
///   the network type and whether uploads are Wi-Fi only.
/// - `isOffline`: Returns true if the network is offline.
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

/// Waits for the first non-null data emitted by a `AsyncValue` provider.
///
/// - `ref`: The Riverpod `Ref` used to read/listen to the provider.
/// - `provider`: The provider whose data is awaited.
/// - `useCache` (default: true): If true, immediately returns the cached data if available.
/// - `timeout`: Optional duration to wait before throwing a [TimeoutException].
///
/// Returns a `Future<T>` that completes with the provider's first data value,
/// or throws if the provider errors or times out.
///
/// Automatically unsubscribes from the provider after receiving data or an error.
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

/// A trigger provider used to manually refresh the network status.
///
/// Incrementing this `StateProvider<int>` will force [networkStatusProvider]
/// to re-evaluate and emit the current network status.
final networkRefreshTriggerProvider = StateProvider<int>((_) => 0);

/// Provides a stream of [NetworkStatus] updates.
///
/// - Initially emits the current network connectivity.
/// - Emits a new [NetworkStatus] whenever connectivity changes.
///
/// Depends on [networkRefreshTriggerProvider] for manual refreshes.
/// Uses `Connectivity().onConnectivityChanged` to listen to network changes.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  ref.watch(networkRefreshTriggerProvider);

  final initial = await Connectivity().checkConnectivity();
  yield NetworkStatus.mapResult(initial);

  await for (final result in Connectivity().onConnectivityChanged) {
    yield NetworkStatus.mapResult(result);
  }
});
