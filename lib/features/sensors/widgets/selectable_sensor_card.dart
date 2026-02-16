import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/app/theme/text_styles.dart';
import '../../../app/routing/routes.dart';

class SelectableSensorCard extends ConsumerWidget {
  final Sensor sensor;
  final Wearable wearable;
  final int sensorIndex;

  const SelectableSensorCard({
    super.key,
    required this.sensor,
    required this.wearable,
    required this.sensorIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingProvider = ref.watch(recordingChartProvider);

    final chartId = "${wearable.deviceId}_${sensor.sensorName}";
    final isSelected = recordingProvider.activeChartId == chartId;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.push(
          Routes.sensordataDetails,
          extra: {
            'sensor': sensor,
            'wearable': wearable,
            'sensorIndex': sensorIndex,
          },
        );
      },
      child: Card(
        color: AppColors.fifty,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: AppTextStyles.footerMedium,
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      ref.read(recordingChartProvider).toggleChart(chartId);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// CHART
              SizedBox(
                height: 220,
                child: SensorChart(
                  allowToggleAxes: false,
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
