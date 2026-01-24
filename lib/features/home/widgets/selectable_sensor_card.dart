import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;

import 'package:openearable/features/home/widgets/sensor_value_card.dart';
import 'package:openearable/features/home/controllers/recording_chart_provider.dart';

class SelectableSensorCard extends StatelessWidget {
  final Sensor sensor;
  final Wearable wearable;

  const SelectableSensorCard({
    super.key,
    required this.sensor,
    required this.wearable,
  });

  @override
  Widget build(BuildContext context) {
    final recordingProvider = context.watch<RecordingChartProvider>();

    // Unique ID for this chart
    final chartId = "${wearable.deviceId}_${sensor.sensorName}";

    final isSelected = recordingProvider.activeChartId == chartId;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER ROW (Title + Checkbox)
            Row(
              children: [
                Expanded(
                  child: Text(
                    sensor.sensorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// Checkbox behaves like radio button
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    context
                        .read<RecordingChartProvider>()
                        .selectChart(chartId);
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Chart
            SizedBox(
              height: 220, // fixed height prevents layout explosion
              child: SensorValueCard(
                sensor: sensor,
                wearable: wearable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
