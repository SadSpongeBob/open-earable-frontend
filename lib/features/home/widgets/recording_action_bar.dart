import 'dart:ui';

import 'package:flutter/material.dart';

class RecordingSelectionActionBar extends StatelessWidget {
  const RecordingSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onDuplicate,
    required this.onMove,
    required this.onDone,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onMove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return ClipRect(
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: Colors.white.withOpacity(0.5),
          child: Row(
              children: [
                TextButton(
                  onPressed: hasSelection ? onDelete : null,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: hasSelection ? onDuplicate : null,
                  child: const Text(
                    'Duplicate',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: hasSelection ? onMove : null,
                  child: const Text(
                    'Move',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
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
          ),       ),
       );
      }
    }