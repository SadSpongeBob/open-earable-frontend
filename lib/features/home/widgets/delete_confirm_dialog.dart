import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.onDelete,
    this.subtitle = 'This action cannot be undone',
    this.deleteLabel = 'Delete',
    this.closeLabel = 'Close',
  });

  final String title;
  final String subtitle;
  final String deleteLabel;
  final String closeLabel;
  final VoidCallback onDelete;

  static Future<void> show(
      BuildContext context, {
        required String title,
        required VoidCallback onDelete,
        String subtitle = 'This action cannot be undone',
        String deleteLabel = 'Delete',
        String closeLabel = 'Close',
      }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: DeleteConfirmDialog(
          title: title,
          subtitle: subtitle,
          deleteLabel: deleteLabel,
          closeLabel: closeLabel,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  bool _working = false;

  Future<void> _handleDelete() async {
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
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.body.copyWith(fontSize: 18, color: Colors.grey[700]),
                ),
              ),

              const SizedBox(height: 12),

              // Delete button row
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: TextButton(
                    onPressed: _working ? null : _handleDelete,
                    child: Text(
                      widget.deleteLabel,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
              ),

              // Close button row
              Container(
                width: 400,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      widget.closeLabel,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 25,
                      ),
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

