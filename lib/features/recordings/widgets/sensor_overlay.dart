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
    
    final chartId = recordingProvider.activeChartId;

    if (!recordingProvider.isOverlayVisible) return const SizedBox.shrink();

    // FIND LOGIC
    SensorDataProvider? activeDataProvider;
    List<String> availableSensorNames = [];

    for (var providers in wearablesProvider.sensorDataProviders.values) {
      for (var provider in providers) {
        String name = provider.sensor.sensorName;
        availableSensorNames.add(name);
        if (name == chartId) {
          activeDataProvider = provider;
        }
      }
    }

    // DEBUG UI: If chartId is null or doesn't match, show what we found
    if (chartId == null || activeDataProvider == null) {
      return Container(
        color: Colors.red.withOpacity(0.8),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DEBUG MODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Selected ID: '$chartId'", style: TextStyle(color: Colors.yellow)),
            Text("Available in WearablesProvider:", style: TextStyle(color: Colors.white)),
            ...availableSensorNames.map((name) => Text("- '$name'", style: TextStyle(color: Colors.white70))),
            if (availableSensorNames.isEmpty) Text("NO SENSORS FOUND IN WEARABLES PROVIDER", style: TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    // ACTUAL CHART UI
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.55)),
        padding: const EdgeInsets.all(12),
        child: ChangeNotifierProvider<SensorDataProvider>.value(
          value: activeDataProvider,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const SensorChart(allowToggleAxes: false),
          ),
        ),
      ),
    );
  }
}