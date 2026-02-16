import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/theme/text_styles.dart';


class SelectSensorsDialog extends StatefulWidget {
  final List<String> available;
  const SelectSensorsDialog({super.key, required this.available});

  static Future<List<String>?> show(BuildContext context, {List<String>? available}) {
    return showAppDialog(context, dialog: SelectSensorsDialog(available: available ?? []));
  }

  @override
  State<SelectSensorsDialog> createState() => _SelectSensorsDialogState();
}

class _SelectSensorsDialogState extends State<SelectSensorsDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final avail = widget.available;

    Widget body;
    if (avail.isEmpty) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text('No sensors available.', style: AppTextStyles.textRegular),

        ],
      );
    } else {
      body = SizedBox(
        height: 240,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: avail.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (c, i) {
            final name = avail[i];
            return CheckboxListTile(
              title: Text(name, style: AppTextStyles.textMedium),
              value: _selected.contains(name),
              onChanged: (v) {
                setState(() {
                  if (v == true) _selected.add(name); else _selected.remove(name);
                });
              },
            );
          },
        ),
      );
    }

    return BaseDialog(
      title: 'Select sensors',
      body: body,
      actions: [
        BaseDialogActionRow(
          child: AppButton.primary(
            text: 'OK',
            onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
            borderRadius: 0,
          ),
        ),
        BaseDialogActionRow(
          topBorder: false,
          bottomRounded: true,
          child: AppButton.ghost(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            borderRadius: 0,
          ),
        ),
      ],
    );
  }
}
