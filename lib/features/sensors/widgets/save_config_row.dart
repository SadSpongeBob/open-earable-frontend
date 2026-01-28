import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/sensors/state/sensor_configuration_storage.dart';
import 'package:openearable/app/theme/text_styles.dart';

class SaveConfigRow extends StatefulWidget {
  const SaveConfigRow({super.key});

  @override
  State<SaveConfigRow> createState() => _SaveConfigRowState();
}

class _SaveConfigRowState extends State<SaveConfigRow> {
  String _configName = '';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextField(
        onChanged: (value) {
          setState(() {
            _configName = value;
          });
        },
        onSubmitted: (value) async {
          setState(() {
            _configName = value.trim();
          });
        },
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'Save as...',
          hintStyle: GlobalTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
        ),
        style: GlobalTextStyles.footnote,
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF2F2F2),
        ),
        onPressed: () async {
          SensorConfigurationProvider provider =
              Provider.of<SensorConfigurationProvider>(context, listen: false);
          Map<String, String> config = provider.toJson();

          if (_configName.isNotEmpty) {
            await SensorConfigurationStorage.saveConfiguration(
              _configName.trim(),
              config,
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Configuration Name Required", 
                    style: GlobalTextStyles.subHeaderMedium,
                  ),
                  content: Text(
                    "Please enter a name for the configuration.",
                    style: GlobalTextStyles.text,
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "OK", 
                        style: GlobalTextStyles.subHeader.copyWith(color: Color(0XFF6E6E6E)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Text(
          "Save", 
          style: GlobalTextStyles.footnote,
        ),
      ),
    );
  }
}
