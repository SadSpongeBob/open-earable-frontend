import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import '../../../app/theme/text_styles.dart';

class DeleteProjectDialog extends StatefulWidget {
  const DeleteProjectDialog({super.key, this.onDelete});

  final VoidCallback? onDelete;

  static Future<void> show(BuildContext context, {VoidCallback? onDelete}) {
    return showAppDialog(
      context,
      dialog: DeleteProjectDialog(onDelete: onDelete),
    );
  }

  @override
  State<DeleteProjectDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteProjectDialog> {
  bool _working = false;

  Future<void> _handleDelete() async {
    if (_working) return;

    setState(() => _working = true);

    try {
      widget.onDelete?.call();
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Do you really want to \ndelete these projects?',
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
