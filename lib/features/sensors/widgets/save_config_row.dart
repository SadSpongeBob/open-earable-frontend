import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/input_box.dart';
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
  late TextEditingController _configController;

  @override
  void initState() {
    super.initState();

    _configController = TextEditingController();

    _configController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _configController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(
      sensorConfigurationProviderFamily(widget.deviceId),
    );
    final storage = ref.read(sensorConfigurationStorageProvider);

    return ListTile(
      title: InputBox(
        controller: _configController,
        hint: 'Save as...',
        onSubmitted: (value) async {
          setState(() {});
        },
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.fifty),
        onPressed: () async {
          final name = _configController.text.trim();
          final config = provider.toJson();

          if (name.isNotEmpty) {
            await storage.saveConfiguration(name, config);
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
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
              ),
            );
          }
        },
        child: Text("Save", style: AppTextStyles.footerRegular),
      ),
    );
  }
}
