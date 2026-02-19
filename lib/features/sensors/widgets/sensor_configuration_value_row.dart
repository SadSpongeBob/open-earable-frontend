import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_detail_view.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A widget that displays a single sensor configuration row for a device.
///
/// Tapping the row opens a bottom sheet showing detailed configuration options
/// for the sensor. The currently selected value (or options) is shown on the row's
/// trailing side. If the sensor is off, "Off" is displayed.
///
/// This widget interacts with [SensorConfigurationProvider] to get and update
/// the selected configuration value and options.
/// 
/// Parameters:
/// - [sensorConfiguration]: The sensor configuration represented by this row.
/// - [deviceId]: The ID of the device to which the sensor configuration belongs.
class SensorConfigurationValueRow extends ConsumerWidget {
  final SensorConfiguration sensorConfiguration;
  final String deviceId;

  const SensorConfigurationValueRow({
    super.key,
    required this.sensorConfiguration,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorConfigNotifier = ref.watch(
      sensorConfigurationProviderFamily(deviceId),
    );

    return ListenableBuilder(
      listenable: sensorConfigNotifier,
      builder: (context, _) {
        return ListTile(
          tileColor: AppColors.fifty,
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (modalContext) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      sensorConfiguration.name,
                      style: AppTextStyles.subheaderMedium,
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ),
                  body: SensorConfigurationDetailView(
                    sensorConfiguration: sensorConfiguration,
                    deviceId: deviceId,
                  ),
                );
              },
            );
          },
          title: Text(sensorConfiguration.name),
          trailing: _isOn(sensorConfigNotifier, sensorConfiguration)
              ? () {
                  if (sensorConfigNotifier.getSelectedConfigurationValue(
                        sensorConfiguration,
                      ) ==
                      null) {
                    return Text(
                      "Internal Error",
                      style: AppTextStyles.footerRegular.copyWith(
                        color: AppColors.sixHundred,
                      ),
                    );
                  }
                  SensorConfigurationValue value = sensorConfigNotifier
                      .getSelectedConfigurationValue(sensorConfiguration)!;
                  if (value is SensorFrequencyConfigurationValue) {
                    SensorFrequencyConfigurationValue freqValue = value;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sensorConfiguration
                            is ConfigurableSensorConfiguration)
                          ...(sensorConfigNotifier
                                  .getSelectedConfigurationOptions(
                                    sensorConfiguration,
                                  ))
                              .map((option) {
                                return Icon(
                                  Icons.bluetooth,
                                  color: AppColors.sixHundred,
                                );
                              }),
                        Text(
                          "${freqValue.frequencyHz} Hz",
                          style: AppTextStyles.footerRegular.copyWith(
                            color: AppColors.sixHundred,
                          ),
                        ),
                      ],
                    );
                  }

                  return Text(
                    value.toString(),
                    style: AppTextStyles.footerRegular.copyWith(
                      color: AppColors.sixHundred,
                    ),
                  );
                }()
              : Text(
                  "Off",
                  style: AppTextStyles.footerRegular.copyWith(
                    color: AppColors.sixHundred,
                  ),
                ),
        );
      },
    );
  }

  /// Returns true if the configuration is currently active/on.
  /// Handles different types of sensor configurations:
  /// - ConfigurableSensorConfiguration: active if any options are selected
  /// - SensorFrequencyConfiguration: active if frequency > 0
  /// - Others: always considered on
  bool _isOn(SensorConfigurationProvider notifier, SensorConfiguration config) {
    bool isOn = false;
    if (config is ConfigurableSensorConfiguration) {
      isOn = notifier.getSelectedConfigurationOptions(config).isNotEmpty;
    } else if (config is SensorFrequencyConfiguration) {
      SensorFrequencyConfigurationValue? value =
          notifier.getSelectedConfigurationValue(config)
              as SensorFrequencyConfigurationValue?;
      isOn = value?.frequencyHz != null && value!.frequencyHz > 0;
    } else {
      isOn = true;
    }

    return isOn;
  }
}
