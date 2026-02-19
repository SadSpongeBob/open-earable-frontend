import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import '../../../app/theme/text_styles.dart';

/// Confirmation dialog shown before performing a delete action.
///
/// Calls [onDelete] when the user confirms and then closes the dialog.
class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.onDelete,
    required this.title,
  });

  /// Callback executed when the delete button is pressed.
  final VoidCallback onDelete;

  /// Title displayed at the top of the dialog.
  final String title;

  /// Displays the delete confirmation dialog.
  ///
  /// Executes [onDelete] if the user confirms the action.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDelete,
    required String title,
  }) {
    return showAppDialog(
      context,
      dialog: DeleteConfirmDialog(onDelete: onDelete, title: title),
    );
  }

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  bool _working = false;

  Future<void> _handleDelete() async {
    if (_working) return;

    setState(() => _working = true);

    try {
      widget.onDelete();
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.title,
      body: Text(
        'This action cannot be undone',
        textAlign: TextAlign.center,
        style: AppTextStyles.textRegular,
      ),
      actions: [
        BaseDialogActionRow(
          child: AppButton.dangerGhost(
            text: 'Delete',
            onPressed: _working ? null : _handleDelete,
            borderRadius: 0,
          ),
        ),
        BaseDialogActionRow(
          topBorder: false,
          bottomRounded: true,
          child: AppButton.ghost(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            borderRadius: 0,
          ),
        ),
      ],
    );
  }
}
