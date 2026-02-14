import 'package:flutter/material.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/pill_menu.dart';

class PlaybackSpeedBadge extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onSpeedChanged;

  const PlaybackSpeedBadge({
    super.key,
    required this.speed,
    required this.onSpeedChanged,
  });

  static const _speeds = <double>[0.25, 0.5, 1.0, 1.5, 2.0];

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
