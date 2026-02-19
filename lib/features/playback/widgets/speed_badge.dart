import 'package:flutter/material.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/pill_menu.dart';

/// A UI component for displaying the current playback speed and letting
/// the user change it.
///
/// Parameters:
/// - [speed]: The current playback speed (e.g., 1.0 for normal speed).
/// - [onSpeedChanged]: Callback invoked when the user selects a new speed.
///
/// Behavior:
/// - Tapping the badge toggles between 1.0x and 0.5x speeds.
/// - Long-pressing opens a menu (via [PillMenuAnchor]) to select from
///   predefined speeds: 0.25x, 0.5x, 1x, 1.5x, 2x.
/// - Displays the speed as a formatted label (e.g., "1x" instead of "1.0x").
class PlaybackSpeedBadge extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onSpeedChanged;

  const PlaybackSpeedBadge({
    super.key,
    required this.speed,
    required this.onSpeedChanged,
  });

  /// The list of supported playback speeds available in the menu.
  static const _speeds = <double>[0.25, 0.5, 1.0, 1.5, 2.0];

  /// Returns a formatted string for a playback speed.
  /// Converts a double like 1.0 to "1x", removing unnecessary ".0".
  String _label(double s) => '${s}x'.replaceAll('.0x', 'x');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSpeedChanged(speed == 1.0 ? 0.5 : 1.0);
      },
      child: AbsorbPointer(
        absorbing: false,
        child: PillMenuAnchor<double>(
          menuWidth: 100,
          value: speed,
          options: _speeds,
          labelOf: _label,
          onChanged: onSpeedChanged,
          openOnTap: false,
          openOnLongPress: true,
          childBuilder: (context, isOpen) {
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSpeedChanged(speed == 1.0 ? 0.5 : 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(_label(speed), style: AppTextStyles.footerRegular),
              ),
            );
          },
        ),
      ),
    );
  }
}
