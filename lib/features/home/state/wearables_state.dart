import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'wearables_provider.dart';
import 'package:openearable/api/models/device/wearable_connector.dart';

final wearablesProvider = ChangeNotifierProvider<WearablesProvider>((ref) {
  return WearablesProvider();
});

final wearableConnectorProvider = Provider<WearableConnector>((ref) => WearableConnector());
