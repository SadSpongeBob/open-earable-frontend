import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A dialog widget that lets the user select a sensor from a list.
///
/// Displays available sensors as radio buttons and notifies the parent
/// immediately when the selection changes. Long-pressing a sensor triggers
/// an optional callback.
///
/// Parameters:
/// - [available]: List of sensors to display for selection.
/// - [initialSelected]: List of initially selected sensors. Defaults to empty.
/// - [onChanged]: Optional callback invoked immediately when the selection changes.
/// - [onLongPress]: Optional callback invoked when a sensor is long-pressed.
class SelectSensorsDialog extends StatefulWidget {
  final List<Sensor> available;
  final List<Sensor> initialSelected;
  final void Function(List<Sensor>)? onChanged;
  final void Function(Sensor)? onLongPress;

  const SelectSensorsDialog({
    super.key,
    required this.available,
    this.initialSelected = const [],
    this.onChanged,
    this.onLongPress,
  });

  /// Displays the select sensors dialog and returns the selected sensor(s).
  ///
  /// Parameters:
  /// - [context]: BuildContext to show the dialog.
  /// - [available]: List of sensors to display. Defaults to empty list.
  /// - [initialSelected]: List of initially selected sensors. Defaults to empty list.
  /// - [onChanged]: Optional callback for immediate selection changes.
  /// - [onLongPress]: Optional callback for long-press on a sensor.
  ///
  /// Returns:
  /// - A [Future<List<Sensor>?>] that completes with the selected sensor in a list,
  ///   or an empty list if nothing was selected or the dialog was closed.
  static Future<List<Sensor>?> show(
    BuildContext context, {
    List<Sensor>? available,
    List<Sensor>? initialSelected,
    void Function(List<Sensor>)? onChanged,
    void Function(Sensor)? onLongPress,
  }) {
    return showAppDialog(
      context,
      dialog: SelectSensorsDialog(
        available: available ?? [],
        initialSelected: initialSelected ?? [],
        onChanged: onChanged,
        onLongPress: onLongPress,
      ),
    );
  }

  @override
  State<SelectSensorsDialog> createState() => _SelectSensorsDialogState();
}

class _SelectSensorsDialogState extends State<SelectSensorsDialog> {
  Sensor? _selected;

  @override
  void initState() {
    super.initState();
    // If there was an initial selection, pick the first element
    if (widget.initialSelected.isNotEmpty) {
      _selected = widget.initialSelected.first;
    }
  }

  /// Updates the currently selected sensor and triggers the [onChanged] callback.
  ///
  /// Parameters:
  /// - [value]: The sensor that was selected. Can be null to deselect.
  ///
  /// Immediately calls [widget.onChanged] with the new selection.
  void _onSelect(Sensor? value) {
    setState(() => _selected = value);
    // notify immediately that selection changed
    if (widget.onChanged != null) {
      widget.onChanged!(_selected == null ? [] : [_selected!]);
    }
  }

  /// Builds the dialog UI.
  ///
  /// Layout:
  /// - Title: "Select sensor"
  /// - Body:
  ///   - If no sensors are available: shows "No sensors available."
  ///   - Otherwise: displays a scrollable list of sensors with radio buttons.
  /// - Actions: Close button that returns the currently selected sensor.
  ///
  /// Behavior:
  /// - Tapping a sensor selects it.
  /// - Long-pressing a sensor triggers [widget.onLongPress].
  /// - The Close button returns the current selection to the caller.
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
      const double itemHeight = 56.0;
      const double maxHeight = 240.0;
      final double desiredHeight = math.min(
        maxHeight,
        avail.length * itemHeight + 8,
      );

      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: desiredHeight),
        child: RadioGroup<Sensor>(
          groupValue: _selected,
          onChanged: _onSelect,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: avail.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final sensor = avail[i];

              return SizedBox(
                height: itemHeight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSelect(sensor),
                    onLongPress: () => widget.onLongPress?.call(sensor),
                    child: ListTile(
                      leading: Radio<Sensor>(value: sensor),
                      title: Text(sensor.name, style: AppTextStyles.textMedium),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return BaseDialog(
      title: 'Select sensor',
      body: body,
      actions: [
        Container(
          decoration: BoxDecoration(
            border: BoxBorder.fromLTRB(
              top: BorderSide(width: 2, color: AppColors.sixHundred),
            ),
          ),
          child: BaseDialogActionRow(
            topBorder: false,
            bottomRounded: true,
            child: AppButton.ghost(
              text: 'Close',
              onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.pop(_selected == null ? <Sensor>[] : <Sensor>[_selected!]);
                }
              }),
              borderRadius: 0,
            ),
          ),
        ),
      ],
    );
  }
}
