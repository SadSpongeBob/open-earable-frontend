import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_device_row.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A view that displays the sensor configurations of all connected wearables.
/// 
/// The specific sensor configurations should be made available via the [SensorConfigurationProvider].
class SensorConfigurationView extends ConsumerWidget {
  final VoidCallback? onSetConfigPressed;

  const SensorConfigurationView({super.key, this.onSetConfigPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearablesNotifier = ref.watch(wearablesProvider);
    final connectedWearables = wearablesNotifier.wearables;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: connectedWearables.isEmpty
            ? [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      "No devices connected",
                      style: GlobalTextStyles.subHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]
            : [
                ...connectedWearables.map((wearable) => 
                  SensorConfigurationDeviceRow(device: wearable)
                ),

                const SizedBox(height: 15),
                
                _buildSetConfigButton(
                  ref: ref,
                  wearables: connectedWearables
                    .where((w) => w.hasCapability<SensorConfigurationManager>())
                    .toList(),
                ),
              ],
    );
  }

  Widget _buildSetConfigButton({
    required WidgetRef ref,
    required List<Wearable> wearables,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F1F1F),
        fixedSize: const Size(240, 55),
      ),
      onPressed: () {
        for (var wearable in wearables) {
          final configProvider = ref.read(
            sensorConfigurationProviderFamily(wearable.deviceId),
          );
          
          for (var entry in configProvider.getSelectedConfigurations()) {
            SensorConfiguration config = entry.$1;
            SensorConfigurationValue value = entry.$2;
            config.setConfiguration(value);
          }
        }
        (onSetConfigPressed ?? () {})();
      },
      child: Text(
          'Set Configurations',
          style: GlobalTextStyles.footnoteMedium.copyWith(color: Color(0xFFF2F2F2)),
        ),
    );
  }
}
