import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class DeleteProjectDialog extends StatefulWidget {
  const DeleteProjectDialog({
    super.key,
    this.onDelete,
  });

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6)),
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
                    style: AuthTextStyles.title.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
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
                  style: AuthTextStyles.body.copyWith(fontSize: 18, color: Colors.grey[700]),
                ),
              ),

              const SizedBox(height: 12),

              // middle box with grey border and Delete button (red text)
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _working ? null : _handleDelete,
                    child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 25)),
                  ),
                ),
              ),
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: TextStyle(color: Colors.grey[700], fontSize: 25)),
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

