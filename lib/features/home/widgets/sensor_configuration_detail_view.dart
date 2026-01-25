import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/features/home/controllers/sensor_configurations_provider.dart';
import 'package:provider/provider.dart';

import 'sensor_config_option_icon_factory.dart';

class SensorConfigurationDetailView extends StatefulWidget {
  final SensorConfiguration sensorConfiguration;

  const SensorConfigurationDetailView({
    super.key,
    required this.sensorConfiguration,
  });
  
  @override
  State<StatefulWidget> createState() {
    return _SensorConfigurationDetailViewState();
  }
}

class _SensorConfigurationDetailViewState extends State<SensorConfigurationDetailView> {
  SensorConfigurationValue? _selectedValue;

  @override
  Widget build(BuildContext context) {
    SensorConfigurationProvider sensorConfigNotifier = Provider.of<SensorConfigurationProvider>(context);
    _selectedValue = sensorConfigNotifier.getSelectedConfigurationValue(widget.sensorConfiguration);

    return ListView(
      children: [
        if (widget.sensorConfiguration is ConfigurableSensorConfiguration)
          ...(widget.sensorConfiguration as ConfigurableSensorConfiguration).availableOptions.map((option) {
            return ListTile(
              leading: Icon(getSensorConfigurationOptionIcon(option), color: Color(0xFF1F1F1F),),
              title: Text(option.name, style: AppTextStyles.text,),
              trailing: Switch(
                value: sensorConfigNotifier.getSelectedConfigurationOptions(widget.sensorConfiguration).contains(option),
                onChanged: (value) {
                  if (value) {
                    sensorConfigNotifier.addSensorConfigurationOption(widget.sensorConfiguration, option);
                  } else {
                    sensorConfigNotifier.removeSensorConfigurationOption(widget.sensorConfiguration, option);
                  }
                },
              ),
            );
          }),
        ListTile(
          leading: Icon(Icons.speed_outlined, color: Color(0xFF1F1F1F),),
          title: Text("Sampling Rate", style: AppTextStyles.text,),
          trailing: Material(
            child: DropdownButton<SensorConfigurationValue>(
              value: sensorConfigNotifier.getSelectedConfigurationValue(widget.sensorConfiguration),
              items: sensorConfigNotifier.getSensorConfigurationValues(widget.sensorConfiguration, distinct: true).where(
                (value) {
                  if (value is SensorFrequencyConfigurationValue) {
                    return value.frequencyHz >= 0.1
                      || value.frequencyHz == 0
                      || sensorConfigNotifier.getSelectedConfigurationValue(widget.sensorConfiguration) == value;
                  }
                  return true;
                },
              ).map((value) {
                if (value is SensorFrequencyConfigurationValue) {
                  return DropdownMenuItem<SensorConfigurationValue>(
                    value: value,
                      child: Text(
                        value.frequencyHz.toStringAsFixed(2), 
                        style: AppTextStyles.text.copyWith(color: Color(0xFF6F6F6F)),
                      ),
                  );
                }
                return DropdownMenuItem<SensorConfigurationValue>(
                  value: value,
                  child: Text(
                    value.key, 
                    style: AppTextStyles.text.copyWith(color: Color(0xFF6F6F6F)),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedValue = value;
                });
                if (_selectedValue != null) {
                  sensorConfigNotifier.addSensorConfiguration(widget.sensorConfiguration, _selectedValue!);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
