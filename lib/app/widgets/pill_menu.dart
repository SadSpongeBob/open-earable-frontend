import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A customizable inline dropdown menu displayed as a "pill".
///
/// [PillMenu] displays a single selected value and allows the user
/// to choose from a list of options when tapped or long-pressed.
/// The currently selected value is highlighted, and each option
/// can have a custom text color via [itemColor].
/// 
/// Parameters:
/// - [value]: Currently selected value. If `null`, the menu shows "Loading" and is disabled.
/// - [options]: List of selectable options.
/// - [labelOf]: Function to get a string label from an option.
/// - [onChanged]: Callback invoked when the user selects a new option.
/// - [itemColor]: Optional function to provide a custom color for each menu item.
/// - [borderRadius]: Border radius for the pill's container. Defaults to 36.
/// - [openOnTap]: Whether tapping opens the menu. Defaults to `true`.
/// - [openOnLongPress]: Whether long pressing opens the menu. Defaults to `false`.
/// - [menuWidth]: Optional fixed width of the dropdown menu.
///
/// [PillMenu] internally uses [PillMenuAnchor], which manages
/// overlay positioning, menu opening/closing, and selection.
class PillMenu<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  final Color? Function(T option)? itemColor;
  final double borderRadius;

  final bool openOnTap;
  final bool openOnLongPress;

  final double? menuWidth;

  const PillMenu({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.itemColor,
    this.borderRadius = 36,
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

        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: AppColors.nineHundred, width: 3),
        );

        return Material(
          color: AppColors.fifty,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: null,
            onLongPress: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      isLoading ? 'Loading' : labelOf(value as T),
                      style: AppTextStyles.footerRegular,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(-3, -10),
                        child: Icon(
                          isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          size: 40,
                          color: AppColors.sevenHundred,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Anchor widget that manages opening the dropdown menu in an overlay.
///
/// [PillMenuAnchor] is used internally by [PillMenu] but can also
/// be used directly for more control over the menu appearance and
/// behavior. It exposes a [childBuilder] function to render the
/// pill based on whether the menu is currently open.
class PillMenuAnchor<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final Color? Function(T option)? itemColor;

  final bool openOnTap;
  final bool openOnLongPress;

  final double? menuWidth;

  final Widget Function(BuildContext context, bool isOpen) childBuilder;

  const PillMenuAnchor({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    required this.childBuilder,
    this.itemColor,
    this.openOnTap = true,
    this.openOnLongPress = false,
    this.menuWidth,
  });

  @override
  State<PillMenuAnchor<T>> createState() => _PillMenuAnchorState<T>();
}

class _PillMenuAnchorState<T> extends State<PillMenuAnchor<T>> {
  final _key = GlobalKey();
  bool _isOpen = false;

  Future<void> _openMenu() async {
    if (widget.value == null) return;

    setState(() => _isOpen = true);

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;

    if (overlay == null || box == null) return;

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = RelativeRect.fromLTRB(
      pos.dx,
      pos.dy + box.size.height + 8,
      overlay.size.width - (pos.dx + box.size.width),
      overlay.size.height - (pos.dy + box.size.height),
    );

    final selected = await showMenu<T>(
      context: context,
      position: rect,
      color: AppColors.zero,
      elevation: 10,
      constraints: BoxConstraints.tightFor(
        width: widget.menuWidth ?? box.size.width,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: widget.options.map((opt) {
        final c = widget.itemColor?.call(opt);
        return PopupMenuItem<T>(
          value: opt,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.labelOf(opt),
            style: AppTextStyles.footerRegular.copyWith(
              color: c ?? AppColors.nineHundred,
            ),
          ),
        );
      }).toList(),
    );

    if (!mounted) return;
    setState(() => _isOpen = false);

    if (selected != null && selected != widget.value) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.value != null;

    return KeyedSubtree(
      key: _key,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (enabled && widget.openOnTap) ? _openMenu : null,
        onLongPress: (enabled && widget.openOnLongPress) ? _openMenu : null,
        child: widget.childBuilder(context, _isOpen),
      ),
    );
  }
}
