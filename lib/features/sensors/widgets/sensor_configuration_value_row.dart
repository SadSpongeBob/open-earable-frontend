import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_detail_view.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A row that displays a sensor configuration and allows the user to select a value.
///
/// The selected value is added to the [SensorConfigurationProvider].
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
      tileColor: Color(0xFFF2F2F2),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (modalContext) {
            return Scaffold(
              appBar: AppBar(
                title: Text(sensorConfiguration.name, style: GlobalTextStyles.subHeaderMedium,),
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
              if (sensorConfigNotifier
                      .getSelectedConfigurationValue(sensorConfiguration) ==
                  null) {
                return Text(
                  "Internal Error",
                  style: GlobalTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
                );
              }
              SensorConfigurationValue value = sensorConfigNotifier
                  .getSelectedConfigurationValue(sensorConfiguration)!;
              if (value is SensorFrequencyConfigurationValue) {
                SensorFrequencyConfigurationValue freqValue = value;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sensorConfiguration is ConfigurableSensorConfiguration)
                      ...(sensorConfigNotifier.getSelectedConfigurationOptions(
                        sensorConfiguration,
                      )).map(
                        (option) {
                          return Icon(Icons.bluetooth, color: Color(0xFF6F6F6F));
                        },
                      ),
                    Text(
                      "${freqValue.frequencyHz} Hz",
                      style: GlobalTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
                    ),
                  ],
                );
              }

              return Text(
                value.toString(),
                style: GlobalTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
              );
            }()
          : Text(
              "Off",
              style: GlobalTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
            ),
    );
    },
    );
  }

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
