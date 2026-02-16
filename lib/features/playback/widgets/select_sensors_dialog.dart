import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/theme/text_styles.dart';


class SelectSensorsDialog extends StatefulWidget {
  final List<String> available;
  final List<String> initialSelected;
  final void Function(List<String>)? onChanged;
  const SelectSensorsDialog({
    super.key,
    required this.available,
    this.initialSelected = const [],
    this.onChanged,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    List<String>? available,
    List<String>? initialSelected,
    void Function(List<String>)? onChanged,
  }) {
    return showAppDialog(
      context,
      dialog: SelectSensorsDialog(
        available: available ?? [],
        initialSelected: initialSelected ?? [],
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<SelectSensorsDialog> createState() => _SelectSensorsDialogState();
}

class _SelectSensorsDialogState extends State<SelectSensorsDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    // If there was an initial selection, pick the first element
    if (widget.initialSelected.isNotEmpty) {
      _selected = widget.initialSelected.first;
    }
  }

  void _onSelect(String? value) {
    setState(() => _selected = value);
    // notify immediately that selection changed
    if (widget.onChanged != null) {
      widget.onChanged!(_selected == null ? [] : [_selected!]);
    }
    // close the dialog immediately with the selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_selected == null ? <String>[] : <String>[_selected!]);
    });
  }

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
            return RadioListTile<String>(
              title: Text(name, style: AppTextStyles.textMedium),
              value: name,
              groupValue: _selected,
              onChanged: _onSelect,
            );
          },
        ),
      );
    }

    return BaseDialog(
      title: 'Select sensor',
      body: body,
      actions: [
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
