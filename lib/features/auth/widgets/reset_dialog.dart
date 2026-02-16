import 'package:flutter/cupertino.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';

class ResetDialog extends StatefulWidget {
  const ResetDialog({super.key, required this.title, required this.message});

  final String title;
  final String message;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showAppDialog(
      context,
      dialog: ResetDialog(title: title, message: message),
    );
  }

  @override
  State<ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<ResetDialog> {
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
