import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import '../../../app/theme/text_styles.dart';

class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.onDelete,
    required this.title,
  });

  final VoidCallback onDelete;
  final String title;

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
