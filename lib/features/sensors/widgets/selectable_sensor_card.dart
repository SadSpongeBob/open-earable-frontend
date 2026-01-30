import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/features/sensors/state/recording_chart_provider.dart';
import 'package:openearable/features/sensors/state/sensor_data_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_value_details.dart';
import 'package:openearable/app/theme/text_styles.dart';

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

    final chartId = "${wearable.deviceId}_${sensor.sensorName}";
    final isSelected = recordingProvider.activeChartId == chartId;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final sensorDataProvider = context.read<SensorDataProvider>();
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: sensorDataProvider,
              child: SensorValueDetail(
                sensor: sensor,
                wearable: wearable,
              ),
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFFF2F2F2),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sensor.sensorName,
                      style: GlobalTextStyles.footnoteMedium,
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      context
                          .read<RecordingChartProvider>()
                          .toggleChart(chartId);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// CHART
              SizedBox(
                height: 220,
                child: Consumer<SensorDataProvider>(
                  builder: (context, provider, child) {
                    return SensorChart(
                      allowToggleAxes: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
