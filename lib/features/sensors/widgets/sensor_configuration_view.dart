import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/home/state/wearables_provider.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_device_row.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A view that displays the sensor configurations of all connected wearables.
/// 
/// The specific sensor configurations should be made available via the [SensorConfigurationProvider].
class SensorConfigurationView extends StatelessWidget {
  final VoidCallback? onSetConfigPressed;

  const SensorConfigurationView({super.key, this.onSetConfigPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<WearablesProvider>(
      builder: (context, wearablesProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: wearablesProvider.wearables.isEmpty
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
                    ...wearablesProvider.wearables.map((wearable) {
                      if (wearable.hasCapability<SensorConfigurationManager>()) {
                        return ChangeNotifierProvider<SensorConfigurationProvider>.value(
                          value: wearablesProvider.getSensorConfigurationProvider(wearable),
                          child: SensorConfigurationDeviceRow(device: wearable),
                        );
                      } else {
                        return SensorConfigurationDeviceRow(device: wearable);
                      }
                    }),
                    const SizedBox(height: 15),
                    _buildSetConfigButton(
                      configProviders: wearablesProvider.wearables
                        .where((wearable) => wearable.hasCapability<SensorConfigurationManager>())
                        .map(
                          (wearable) => wearablesProvider.getSensorConfigurationProvider(wearable),
                        ).toList(),
                    ),
                  ],
        );
      },
    );
  }

  Widget _buildSetConfigButton({required List<SensorConfigurationProvider> configProviders}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F1F1F),
        fixedSize: const Size(240, 55),
      ),
      onPressed: () {
        for (SensorConfigurationProvider notifier in configProviders) {
          notifier.getSelectedConfigurations().forEach((entry) {
            SensorConfiguration config = entry.$1;
            SensorConfigurationValue value = entry.$2;
            config.setConfiguration(value);
          });
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

