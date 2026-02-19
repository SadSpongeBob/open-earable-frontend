import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/features/home/state/wearables_state.dart';

/// An overlay widget that displays a sensor chart on top of a video.
///
/// The chart is only shown if:
/// 1. A chart ID is active in [recordingChartProvider].
/// 2. The overlay is marked as visible in [recordingChartProvider].
/// 3. A connected wearable has a sensor matching the chart ID.
///
/// If any condition is not met, the widget returns an empty [SizedBox].
///
/// The overlay displays:
/// - The matched sensor's name
/// - A [SensorChart] for the matched device and sensor index
class VideoSensorOverlay extends ConsumerWidget {
  const VideoSensorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingProvider = ref.watch(recordingChartProvider);
    final chartId = recordingProvider.activeChartId;

    if (chartId == null || !recordingProvider.isOverlayVisible) {
      return const SizedBox.shrink();
    }

    final wearablesNotifier = ref.watch(wearablesProvider);
    final String selectedId = chartId.toLowerCase().split('_').last.trim();

    int? matchedSensorIndex;
    String? matchedDeviceId;

    for (var wearable in wearablesNotifier.wearables) {
      final providers = wearablesNotifier.getSensorDataProviders(wearable);
      
      for (int i = 0; i < providers.length; i++) {
        String sensorName = providers[i].sensor.sensorName.toLowerCase().trim();

        if (selectedId.contains(sensorName) || sensorName.contains(selectedId)) {
          matchedDeviceId = wearable.deviceId;
          matchedSensorIndex = i;
          break;
        }
      }
      if (matchedDeviceId != null) break;
    }

    if (matchedDeviceId == null || matchedSensorIndex == null) {
      return const SizedBox.shrink();
    }

    // CHART
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 250,
        width: double.infinity,
        // Using withAlpha for consistent color manipulation
        decoration: BoxDecoration(color: AppColors.fifty.withAlpha(140)),
        padding: const EdgeInsets.all(12), // Uniform padding
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // We use Expanded or just the chart now that there's no Column
            child: SensorChart(
              allowToggleAxes: false,
              deviceId: matchedDeviceId,
              sensorIndex: matchedSensorIndex,
            ),
          ),
        ),
      ),
    );
  }
}
