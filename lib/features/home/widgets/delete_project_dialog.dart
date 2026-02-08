import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/app_button.dart';
import '../../../app/theme/text_styles.dart';

class DeleteProjectDialog extends StatefulWidget {
  const DeleteProjectDialog({super.key, this.onDelete});

  final VoidCallback? onDelete;

  static Future<void> show(BuildContext context, {VoidCallback? onDelete}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(child: DeleteProjectDialog(onDelete: onDelete)),
    );
  }

  @override
  State<DeleteProjectDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteProjectDialog> {
  bool _working = false;

  Future<void> _handleDelete() async {
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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 400,
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.fifty,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: AppColors.fiveHundred,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                child: Center(
                  child: Text(
                    'Do you really want to \ndelete these projects?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subheaderBold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'This action cannot be undone',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.textRegular,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.fifty,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.sixHundred,
                      width: 2,
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: AppButton.dangerGhost(
                    text: 'Delete',
                    onPressed: _working ? null : _handleDelete,
                    borderRadius: 0,
                  ),
                ),
              ),
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.fifty,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: AppButton.ghost(
                    text: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    borderRadius: 0,
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
