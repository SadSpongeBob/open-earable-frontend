import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
//import 'package:openearable/app/theme/text_styles.dart';

class VideoSensorOverlay extends ConsumerWidget {
  const VideoSensorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingProvider = ref.watch(recordingChartProvider);
    final chartId = recordingProvider.activeChartId;

    //if (chartId == null || !recordingProvider.isOverlayVisible) {
      //return const SizedBox.shrink();
    //}

    if (chartId == null || !recordingProvider.shouldShowOverlay) {
      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.red,
          padding: const EdgeInsets.all(4),
          child: Text("DEBUG: ID=$chartId, Visible=${recordingProvider.shouldShowOverlay}", 
            style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      );
    } 

    final wearablesNotifier = ref.watch(wearablesProvider);
    final String selectedId = chartId.toLowerCase().split('_').last.trim();

    int? matchedSensorIndex;
    String? matchedDeviceId;
    String? matchedSensorName;

    for (var wearable in wearablesNotifier.wearables) {
      final providers = wearablesNotifier.getSensorDataProviders(wearable);
      
      for (int i = 0; i < providers.length; i++) {
        String sensorName = providers[i].sensor.sensorName.toLowerCase().trim();

        if (selectedId.contains(sensorName) || sensorName.contains(selectedId)) {
          matchedSensorName = sensorName;
          matchedDeviceId = wearable.deviceId;
          matchedSensorIndex = i;
          break;
        }
      }
      return Text('ID=$matchedSensorName');
      //if (matchedDeviceId != null) break;
    }

    //if (matchedDeviceId == null || matchedSensorIndex == null) {
      //return const SizedBox.shrink();
    //}
    if (matchedDeviceId == null || matchedSensorIndex == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.blue,
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(8),
          child: Text("DEBUG: Searching '$selectedId' but no sensor matched!", 
            style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    // CHART
    return Align(
  alignment: Alignment.bottomCenter,
  child: Container(
    color: Colors.green,
    height: 250,
    width: double.infinity,
    child: Center(
      child: Text(
        "OVERLAY ACTIVE\n"
        "device=$matchedDeviceId\n"
        "index=$matchedSensorIndex",
        style: const TextStyle(color: Colors.black),
      ),
    ),
  ),
);
  }
}
