import 'package:flutter/cupertino.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';

/// A reusable alert dialog that displays a title, message, and a single
/// confirmation action.
///
/// This dialog is built on top of [BaseDialog] and provides a standardized
/// alert UI used across the application for simple informational messages
/// and user acknowledgements.
class AppAlertDialog extends StatefulWidget {
  const AppAlertDialog({super.key, required this.title, required this.message});

  /// The title displayed at the top of the alert dialog.
  final String title;

  /// The message content shown in the body of the dialog.
  final String message;

  /// Shows an [AppAlertDialog] using the app's dialog presentation system.
  ///
  /// [context] is the build context used to display the dialog.
  /// [title] is the dialog headline text.
  /// [message] is the main content displayed in the dialog body.
  ///
  /// Returns a [Future] that completes when the dialog is dismissed.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showAppDialog(
      context,
      dialog: AppAlertDialog(title: title, message: message),
    );
  }

  @override
  State<AppAlertDialog> createState() => _AppAlertDialogState();
}

class _AppAlertDialogState extends State<AppAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.title,
      body: Text(
        widget.message,
        style: AppTextStyles.textRegular,
        textAlign: TextAlign.center,
      ),
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
              text: 'Ok',
              onPressed: () => Navigator.of(context).pop(),
              borderRadius: 0,
            ),
          ),
        ),
      ],
    );
  }
}
