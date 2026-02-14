import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

class PillMenu<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  final Color? Function(T option)? itemColor;
  final double borderRadius;

  final bool openOnTap;
  final bool openOnLongPress;

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
  });

  @override
  Widget build(BuildContext context) {
    return _PillMenuAnchor<T>(
      value: value,
      options: options,
      labelOf: labelOf,
      onChanged: onChanged,
      itemColor: itemColor,
      borderRadius: borderRadius,
      openOnTap: openOnTap,
      openOnLongPress: openOnLongPress,
    );
  }
}

class _PillMenuAnchor<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final Color? Function(T option)? itemColor;
  final double borderRadius;

  final bool openOnTap;
  final bool openOnLongPress;

  const _PillMenuAnchor({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    required this.itemColor,
    required this.borderRadius,
    required this.openOnTap,
    required this.openOnLongPress,
  });

  @override
  State<_PillMenuAnchor<T>> createState() => _PillMenuAnchorState<T>();
}

class _PillMenuAnchorState<T> extends State<_PillMenuAnchor<T>> {
  final _key = GlobalKey();
  bool _isOpen = false;

  Future<void> _openMenu() async {
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
      constraints: BoxConstraints.tightFor(width: box.size.width),
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
    final isLoading = widget.value == null;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: BorderSide(color: AppColors.nineHundred, width: 3),
    );

    return Material(
      key: _key,
      color: AppColors.fifty,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: (!isLoading && widget.openOnTap) ? _openMenu : null,
        onLongPress: (!isLoading && widget.openOnLongPress) ? _openMenu : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  isLoading ? 'Loading' : widget.labelOf(widget.value as T),
                  style: AppTextStyles.footerRegular,
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 6),

              SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(-3, -10),
                    child: Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
  }
}
