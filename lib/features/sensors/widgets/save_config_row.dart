import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/features/sensors/state/sensor_configuration_storage.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/app/theme/text_styles.dart';

class SaveConfigRow extends ConsumerStatefulWidget {
  final String deviceId;
  
  const SaveConfigRow({super.key, required this.deviceId});

  @override
  ConsumerState<SaveConfigRow> createState() => _SaveConfigRowState();
}

class _SaveConfigRowState extends ConsumerState<SaveConfigRow> {
  String _configName = '';

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(sensorConfigurationProviderFamily(widget.deviceId));
    final storage = ref.read(sensorConfigurationStorageProvider);

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
          hintStyle: AppTextStyles.footerRegular.copyWith(color: AppColors.sevenHundred),
        ),
        style: AppTextStyles.footerRegular,
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.fifty,
        ),
        onPressed: () async {
          Map<String, String> config = provider.toJson();

          if (_configName.isNotEmpty) {
            await storage.saveConfiguration(
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
                    style: AppTextStyles.subheaderMedium,
                  ),
                  content: Text(
                    "Please enter a name for the configuration.",
                    style: AppTextStyles.textRegular,
                  ),
                  actions: [
                    AppButton.ghost(
                      text: 'Ok',
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
          style: AppTextStyles.footerRegular,
        ),
      ),
    );
  }
}
