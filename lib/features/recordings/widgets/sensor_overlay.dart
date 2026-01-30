import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/sensors/state/recording_chart_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';

class VideoSensorOverlay extends StatelessWidget {
  const VideoSensorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingProvider = context.watch<RecordingChartProvider>();
    final chartId = recordingProvider.activeChartId;

    if (chartId == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
        ),
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SensorChart(
            allowToggleAxes: false,
          ),
        ),
      ),
    );
  }
}
