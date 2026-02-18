import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'wearables_provider.dart';
import 'package:openearable/api/models/device/wearable_connector.dart';

/// Riverpod provider that provides the [WearablesProvider] which manages scanning,
/// connections, and state of OpenEarable devices.
final wearablesProvider = ChangeNotifierProvider<WearablesProvider>((ref) {
  return WearablesProvider();
});

/// Riverpod provider that provides a [WearableConnector] for handling device 
/// connection operations.
final wearableConnectorProvider = Provider<WearableConnector>((ref) => WearableConnector());
