import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A details page that displays real-time chart data for a specific sensor.
///
/// This page shows:
/// - The sensor name as a title
/// - A [SensorChart] visualizing live data from the selected wearable sensor
///
/// The chart is configured to allow axis toggling and is linked to the
/// provided [wearable.deviceId] and [sensorIndex].
///
/// Parameters:
/// - [sensor]: The sensor whose data should be visualized.
/// - [wearable]: The wearable device providing the sensor data.
/// - [sensorIndex]: The index of the sensor within the wearable's sensor list.
class SensorDetailsPage extends StatelessWidget {
  final Sensor sensor;
  final Wearable wearable;
  final int sensorIndex;

  const SensorDetailsPage({
    super.key,
    required this.sensor,
    required this.wearable,
    required this.sensorIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Go Back", style: AppTextStyles.textMedium)),
        body: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Text(sensor.sensorName, style: AppTextStyles.titleBold),
              const SizedBox(height: 30),
              Expanded(
                child: SensorChart(
                  allowToggleAxes: true,
                  deviceId: wearable.deviceId,
                  sensorIndex: sensorIndex,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
