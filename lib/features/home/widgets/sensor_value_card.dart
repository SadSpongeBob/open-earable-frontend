import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/home/controllers/sensor_data_provider.dart';
import 'package:openearable/features/home/widgets/sensor_chart.dart';
import 'package:provider/provider.dart';

class SensorValueCard extends StatelessWidget {
  final Sensor sensor;
  final Wearable wearable;

  const SensorValueCard({
    super.key,
    required this.sensor,
    required this.wearable,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            SizedBox(
              height: 180,
              child: SensorChart(
                allowToggleAxes: false,
              ),
            ),
          ],
        );
      },
    );
  }
}