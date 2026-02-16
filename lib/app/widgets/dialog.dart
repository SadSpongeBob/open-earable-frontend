import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required Widget dialog,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: Material(color: Colors.transparent, child: dialog),
        ),
      );
    },
  );
}

class BaseDialog extends StatelessWidget {
  final String? title;
  final Widget body;

  final double width;
  final double? height;
  final double borderRadius;

  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry bodyPadding;

  final List<Widget> actions;

  const BaseDialog({
    super.key,
    this.title,
    required this.body,
    required this.actions,
    this.width = 400,
    this.height,
    this.borderRadius = 36,
    this.headerPadding = const EdgeInsets.only(top: 20, left: 16, right: 16),
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.fifty,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.fiveHundred,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              title != null
                  ? Padding(
                      padding: headerPadding,
                      child: Center(
                        child: Text(title!, style: AppTextStyles.subheaderBold),
                      ),
                    )
                  : const SizedBox(height: 0),
              const SizedBox(height: 10),

              Padding(padding: bodyPadding, child: body),

              const SizedBox(height: 15),

              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class BaseDialogActionRow extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final bool topBorder;
  final bool bottomRounded;

  const BaseDialogActionRow({
    super.key,
    required this.child,
    this.width = 400,
    this.height = 50,
    this.topBorder = true,
    this.bottomRounded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.fifty,
        border: topBorder
            ? Border.symmetric(
                horizontal: BorderSide(color: AppColors.sixHundred, width: 2),
              )
            : null,
        borderRadius: bottomRounded ? BorderRadius.circular(36) : null,
      ),
      child: Align(alignment: Alignment.center, child: child),
    );
  }
}
