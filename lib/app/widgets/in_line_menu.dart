import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/pill_menu.dart';

class InlineMenu<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  final Color? Function(T option)? itemColor;
  final bool openOnTap;
  final bool openOnLongPress;
  final double? menuWidth;

  const InlineMenu({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.itemColor,
    this.openOnTap = true,
    this.openOnLongPress = false,
    this.menuWidth,
  });

  @override
  Widget build(BuildContext context) {
    return PillMenuAnchor<T>(
      value: value,
      options: options,
      labelOf: labelOf,
      onChanged: onChanged,
      itemColor: itemColor,
      openOnTap: openOnTap,
      openOnLongPress: openOnLongPress,
      menuWidth: menuWidth,
      childBuilder: (context, isOpen) {
        final isLoading = value == null;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLoading ? 'Loading' : labelOf(value as T),
              style: AppTextStyles.footerMedium,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.sevenHundred,
            ),
          ],
        );
      },
    );
  }
}
