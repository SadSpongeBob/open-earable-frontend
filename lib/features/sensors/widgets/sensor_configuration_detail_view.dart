import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';

class SensorConfigurationDetailView extends ConsumerWidget {
  final SensorConfiguration sensorConfiguration;
  final String deviceId;

  const SensorConfigurationDetailView({
    super.key,
    required this.sensorConfiguration,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorConfigNotifier = ref.watch(
      sensorConfigurationProviderFamily(deviceId),
    );

    return ListView(
      children: [
        if (sensorConfiguration is ConfigurableSensorConfiguration)
          ...(sensorConfiguration as ConfigurableSensorConfiguration)
              .availableOptions
              .map((option) {
                return ListTile(
                  leading: Icon(Icons.bluetooth, color: AppColors.nineHundred),
                  title: Text(option.name, style: AppTextStyles.textRegular),
                  trailing: Switch(
                    value: sensorConfigNotifier
                        .getSelectedConfigurationOptions(sensorConfiguration)
                        .contains(option),
                    onChanged: (value) {
                      if (value) {
                        sensorConfigNotifier.addSensorConfigurationOption(
                          sensorConfiguration,
                          option,
                        );
                      } else {
                        sensorConfigNotifier.removeSensorConfigurationOption(
                          sensorConfiguration,
                          option,
                        );
                      }
                    },
                  ),
                );
              }),
        ListTile(
          leading: Icon(Icons.speed_outlined, color: AppColors.nineHundred),
          title: Text("Sampling Rate", style: AppTextStyles.textRegular),
          trailing: Material(
            child: DropdownButton<SensorConfigurationValue>(
              value: sensorConfigNotifier.getSelectedConfigurationValue(
                sensorConfiguration,
              ),
              items: sensorConfigNotifier
                  .getSensorConfigurationValues(
                    sensorConfiguration,
                    distinct: true,
                  )
                  .where((value) {
                    if (value is SensorFrequencyConfigurationValue) {
                      return value.frequencyHz >= 0.1 ||
                          value.frequencyHz == 0 ||
                          sensorConfigNotifier.getSelectedConfigurationValue(
                                sensorConfiguration,
                              ) ==
                              value;
                    }
                    return true;
                  })
                  .map((value) {
                    if (value is SensorFrequencyConfigurationValue) {
                      return DropdownMenuItem<SensorConfigurationValue>(
                        value: value,
                        child: Text(
                          value.frequencyHz.toStringAsFixed(2),
                          style: AppTextStyles.textRegular.copyWith(
                            color: AppColors.sixHundred,
                          ),
                        ),
                      );
                    }
                    return DropdownMenuItem<SensorConfigurationValue>(
                      value: value,
                      child: Text(
                        value.key,
                        style: AppTextStyles.textRegular.copyWith(
                          color: AppColors.sixHundred,
                        ),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  sensorConfigNotifier.addSensorConfiguration(
                    sensorConfiguration,
                    value,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
