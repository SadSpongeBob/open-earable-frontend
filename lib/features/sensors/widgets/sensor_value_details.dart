import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/app/theme/text_styles.dart';

class SensorValueDetail extends StatelessWidget {
  final Sensor sensor;
  final Wearable wearable;
  final int sensorIndex;

  const SensorValueDetail({
    super.key, 
    required this.sensor, 
    required this.wearable,
    required this.sensorIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Go Back", style: GlobalTextStyles.textMedium),
        ),
        body: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Text(sensor.sensorName, style: GlobalTextStyles.titleBold),
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
