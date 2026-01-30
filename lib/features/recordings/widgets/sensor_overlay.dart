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
    // 1. Watch both providers
    final recordingProvider = context.watch<RecordingChartProvider>();
    final wearablesProvider = context.watch<WearablesProvider>();
    
    final chartId = recordingProvider.activeChartId;
    print("ACTIVE CHART ID: $chartId");

    // 2. Hide if no selection or overlay toggled off
    if (chartId == null || !recordingProvider.isOverlayVisible) {
      return const SizedBox.shrink();
    }

    // 3. Find the matching SensorDataProvider from the connected wearables
    SensorDataProvider? activeDataProvider;
    
    for (var providers in wearablesProvider.sensorDataProviders.values) {
      for (var provider in providers) {
        print("COMPARING: ${provider.sensor.sensorName} WITH $chartId");
        // We match based on the sensor name (which usually acts as the ID)
        if (provider.sensor.sensorName == chartId) {
          activeDataProvider = provider;
          break;
        }
      }
      if (activeDataProvider != null) break;
    }

    // 4. If not found (e.g., device disconnected), show nothing
    if (activeDataProvider == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
        ),
        padding: const EdgeInsets.all(12),
        // 5. Provide the EXACT instance found in WearablesProvider
        child: ChangeNotifierProvider<SensorDataProvider>.value(
          value: activeDataProvider,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const SensorChart(
              allowToggleAxes: false,
            ),
          ),
        ),
      ),
    );
  }
}