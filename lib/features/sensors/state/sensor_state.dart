import 'package:flutter_riverpod/legacy.dart';
import 'sensor_configurations_provider.dart';
import 'sensor_data_provider.dart';
import 'recording_chart_provider.dart';
import 'package:openearable/features/home/state/wearables_state.dart';

final sensorConfigurationProviderFamily = 
    ChangeNotifierProvider.family<SensorConfigurationProvider, String>((ref, deviceId) {
  final wearablesNotifier = ref.watch(wearablesProvider);
  final wearable = wearablesNotifier.wearables.firstWhere(
    (w) => w.deviceId == deviceId,
    orElse: () => throw StateError('No wearable found with ID $deviceId'),
  );
  return wearablesNotifier.getSensorConfigurationProvider(wearable);
});

final sensorDataProviderFamily = 
    ChangeNotifierProvider.family<SensorDataProvider, (String deviceId, int sensorIndex)>((ref, arg) {
  final deviceId = arg.$1;
  final index = arg.$2;
  
  final wearablesNotifier = ref.watch(wearablesProvider);
  final wearable = wearablesNotifier.wearables.firstWhere(
    (w) => w.deviceId == deviceId,
    orElse: () => throw StateError('No wearable found with ID $deviceId'),
  );
  return wearablesNotifier.getSensorDataProviders(wearable)[index];
});


final recordingChartProvider =
    ChangeNotifierProvider<RecordingChartProvider>((ref) {
  return RecordingChartProvider();
});
