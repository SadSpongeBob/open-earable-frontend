import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/pill_menu.dart';

/// A compact, inline dropdown menu for selecting from a list of options.
///
/// [InlineMenu] displays the currently selected value and a dropdown indicator. 
/// Tapping (or long-pressing, if enabled) opens a menu showing all available options. 
/// Users can select an option, which triggers the [onChanged] callback.
///
/// This widget is generic over type [T], allowing any type of selectable options.
///
/// Parameters:
/// - [value]: The currently selected option. Can be null to indicate a loading state.
/// - [options]: The list of all available options to choose from.
/// - [labelOf]: A function that returns a `String` label for a given option of type [T].
/// - [onChanged]: Callback invoked when the user selects a new option.
/// - [itemColor]: Optional function returning a `Color` for a given option, allowing per-item coloring.
/// - [openOnTap]: Whether the menu opens when the user taps on it (default: true).
/// - [openOnLongPress]: Whether the menu opens when the user long-presses (default: false).
/// - [menuWidth]: Optional fixed width for the dropdown menu.
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
