import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// Displays a custom dialog with optional bottom inset animation.
///
/// This wraps [showDialog] and ensures that the dialog is properly
/// padded above the keyboard when it appears.
///
/// Parameters:
/// - [context]: The BuildContext to show the dialog in.
/// - [dialog]: The content widget of the dialog.
/// - [barrierDismissible]: Whether tapping outside the dialog closes it (default: true).
///
/// Returns a [Future] that completes when the dialog is dismissed, returning
/// a value of type [T] if provided.
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

/// A reusable base dialog widget with customizable title, body, and actions.
///
/// This provides a consistent card-style dialog with rounded corners,
/// optional title, and a column of content and action buttons.
///
/// Parameters:
/// - [title]: Optional title displayed at the top of the dialog.
/// - [body]: The main content of the dialog.
/// - [actions]: A list of widgets representing dialog actions (e.g., buttons).
/// - [width]: Width of the dialog (default: 400).
/// - [height]: Optional fixed height of the dialog.
/// - [borderRadius]: Corner radius of the dialog (default: 36).
/// - [headerPadding]: Padding around the title.
/// - [bodyPadding]: Padding around the body content.
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

/// A container for dialog actions with optional top border and rounded bottom.
///
/// This widget is intended to be used inside [BaseDialog] to display a
/// row of actions such as buttons, maintaining consistent height, width,
/// and border styling.
///
/// Parameters:
/// - [child]: The content widget inside the action row.
/// - [width]: Width of the row (default: 400).
/// - [height]: Height of the row (default: 50).
/// - [topBorder]: Whether to display a top border (default: true).
/// - [bottomRounded]: Whether to round the bottom corners (default: false).
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
