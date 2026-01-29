import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProjectSelectionActionBar extends StatelessWidget {
  const ProjectSelectionActionBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
    required this.onDone,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final showRename = selectedCount == 1;

    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          TextButton(
            onPressed: selectedCount == 0 ? null : onDelete,
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          const SizedBox(width: 10),

          TextButton(
            onPressed: selectedCount == 0 ? null : onDuplicate,
            child: const Text(
              'Duplicate',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),

          if (showRename) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRename,
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],

          const Spacer(),

          TextButton(
            onPressed: onDone,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
