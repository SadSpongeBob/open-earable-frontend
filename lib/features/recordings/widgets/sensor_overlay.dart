import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/sensors/state/recording_chart_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/features/sensors/state/sensor_data_provider.dart';
import 'package:openearable/features/home/state/wearables_provider.dart';

class VideoSensorOverlay extends StatelessWidget {
  const VideoSensorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingProvider = context.watch<RecordingChartProvider>();
    final wearablesProvider = context.watch<WearablesProvider>();

    if (!recordingProvider.isOverlayVisible) return const SizedBox.shrink();

    // 1. Get the ID
    final chartId = recordingProvider.activeChartId;

    // 2. Existing null check
    if (chartId == null || !recordingProvider.isOverlayVisible) {
      return const SizedBox.shrink();
    } 

    // 3. Create a non-nullable version for the loop
    final String selectedId = chartId.toLowerCase();

    SensorDataProvider? activeDataProvider;

    for (var providers in wearablesProvider.sensorDataProviders.values) {
      for (var provider in providers) {
        // 4. Compare using the non-nullable selectedId
        String sensorName = provider.sensor.sensorName.toLowerCase();
    
        if (selectedId.contains(sensorName)) {
          activeDataProvider = provider;
          break;
        }
      }
      if (activeDataProvider != null) break;
    }

    if (activeDataProvider == null) {
      return const SizedBox.shrink();
    }

    // ACTUAL CHART UI
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.55)),
        padding: const EdgeInsets.all(12),
        child: Material(
          color: Colors.transparent,
          child: ChangeNotifierProvider<SensorDataProvider>.value(
            value: activeDataProvider,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const SensorChart(allowToggleAxes: false),
            ),
          ),
        ),
      ),
    );
  }
}