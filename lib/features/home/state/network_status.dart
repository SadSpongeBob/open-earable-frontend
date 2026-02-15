import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { wifi, mobile, offline }

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield _mapResult(initial);

  await for (final result in Connectivity().onConnectivityChanged) {
    yield _mapResult(result);
  }
});

NetworkStatus _mapResult(ConnectivityResult result) {
  return switch (result) {
    ConnectivityResult.wifi => NetworkStatus.wifi,
    ConnectivityResult.mobile => NetworkStatus.mobile,
    _ => NetworkStatus.offline,
  };
}
