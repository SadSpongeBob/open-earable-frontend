import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:openearable/features/home/controllers/sensor_configurations_provider.dart';
import 'package:openearable/features/home/controllers/sensor_configuration_storage.dart';
import 'package:openearable/app/theme/text_styles.dart';

import 'package:openearable/app/utils/logger.dart';
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
          hintStyle: AppTextStyles.footnote.copyWith(color: Color(0xFF6F6F6F)),
        ),
        style: AppTextStyles.footnote,
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF2F2F2),
        ),
        onPressed: () async {
          SensorConfigurationProvider provider =
              Provider.of<SensorConfigurationProvider>(context, listen: false);
          Map<String, String> config = provider.toJson();

          logger.d("Saving configuration: $_configName with data: $config");

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
                    style: AppTextStyles.subHeaderMedium,
                  ),
                  content: Text(
                    "Please enter a name for the configuration.",
                    style: AppTextStyles.text,
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "OK", 
                        style: AppTextStyles.subHeader.copyWith(color: Color(0XFF6E6E6E)),
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
          style: AppTextStyles.footnote,
        ),
      ),
    );
  }
}
