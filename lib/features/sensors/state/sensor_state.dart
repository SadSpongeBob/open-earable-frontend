import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'sensor_configurations_provider.dart';
import 'sensor_data_provider.dart';
import 'recording_chart_provider.dart';
import 'package:openearable/features/home/state/wearables_state.dart';

/// Provides a [SensorConfigurationProvider] for a specific wearable device.
///
/// Parameters:
/// - [deviceId]: The unique identifier of the wearable device.
///
/// Behavior:
/// - Watches [wearablesProvider] to access the current list of connected wearables.
/// - Returns the sensor configuration provider associated with the matching wearable.
///
/// Throws:
/// - [StateError] if no wearable with the given [deviceId] is found.
final sensorConfigurationProviderFamily = 
    Provider.family<SensorConfigurationProvider, String>((ref, deviceId) {
  final wearablesNotifier = ref.watch(wearablesProvider);
  final wearable = wearablesNotifier.wearables.firstWhere(
    (w) => w.deviceId == deviceId,
    orElse: () => throw StateError('No wearable found with ID $deviceId'),
  );
  return wearablesNotifier.getSensorConfigurationProvider(wearable);
});

/// Provides a [SensorDataProvider] for a specific sensor of a wearable device.
///
/// Parameters:
/// - [deviceId]: The unique identifier of the wearable device.
/// - [sensorIndex]: The index of the sensor within the wearable.
///
/// Usage:
/// Pass a tuple `(deviceId, sensorIndex)` to retrieve the corresponding
/// sensor data provider.
///
/// Behavior:
/// - Watches [wearablesProvider] for the current wearable state.
/// - Locates the wearable by [deviceId].
/// - Returns the sensor data provider at the given [sensorIndex].
///
/// Throws:
/// - [StateError] if no wearable with the given [deviceId] exists.
/// - [RangeError] if the [sensorIndex] is out of bounds.
final sensorDataProviderFamily = 
    Provider.family<SensorDataProvider, (String deviceId, int sensorIndex)>((ref, arg) {
  final deviceId = arg.$1;
  final index = arg.$2;
  final wearablesNotifier = ref.watch(wearablesProvider);
  final wearable = wearablesNotifier.wearables.firstWhere(
    (w) => w.deviceId == deviceId,
    orElse: () => throw StateError('No wearable found with ID $deviceId'),
  );
  return wearablesNotifier.getSensorDataProviders(wearable)[index];
});

/// Provides a global [RecordingChartProvider] for managing chart selection
/// and overlay visibility state.
///
/// Lifecycle:
/// - Marked with `ref.keepAlive()` to persist state even when no listeners
///   are actively watching the provider.
/// - Useful for maintaining UI chart state across navigation and rebuilds.
final recordingChartProvider =
    ChangeNotifierProvider<RecordingChartProvider>((ref) {
  ref.keepAlive();
  return RecordingChartProvider();
});
