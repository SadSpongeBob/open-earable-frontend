import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/alert_dialog.dart';
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
    final provider = ref.watch(
      sensorConfigurationProviderFamily(widget.deviceId),
    );
    final storage = ref.read(sensorConfigurationStorageProvider);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
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
              hintStyle: AppTextStyles.footerRegular.copyWith(
                color: AppColors.sevenHundred,
              ),
            ),
            style: AppTextStyles.footerRegular,
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fifty),
            onPressed: () async {
              Map<String, String> config = provider.toJson();

              if (_configName.isNotEmpty) {
                await storage.saveConfiguration(_configName.trim(), config);
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AppAlertDialog(
                      title: "Configuration Name",
                      message: "Please enter a name for the configuration!",
                    );
                  },
                );
              }
            },
            child: Text("Save", style: AppTextStyles.footerRegular),
          ),
        );
      },
    );
  }
}
