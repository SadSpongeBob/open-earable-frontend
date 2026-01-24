import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/home/widgets/sensor_chart.dart';

class SensorValueDetail extends StatelessWidget {
  final Sensor sensor;
  final Wearable wearable;

  const SensorValueDetail({super.key, required this.sensor, required this.wearable});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sensor.sensorName, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(wearable.name, style: Theme.of(context).textTheme.bodyMedium),
            Expanded(
              child: SensorChart(allowToggleAxes: true),
            ),
          ],
        ),
      ),
    );
  }
}
