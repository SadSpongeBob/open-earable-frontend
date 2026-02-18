import 'dart:ui';

import 'package:flutter/material.dart';

/// Action bar displayed when one or more recordings are selected.
///
/// Provides options for:
/// - Deleting selected recordings
/// - Duplicating selected recordings
/// - Moving selected recordings to another folder
/// - Completing selection mode ("Done")
///
/// Applies a blurred translucent background for visual emphasis.
class RecordingSelectionActionBar extends StatelessWidget {
  const RecordingSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onDuplicate,
    required this.onMove,
    required this.onDone,
  });

  /// Number of recordings currently selected.
  final int selectedCount;

  /// Callback when "Delete" is tapped.
  final VoidCallback onDelete;

  /// Callback when "Duplicate" is tapped.
  final VoidCallback onDuplicate;

  /// Callback when "Move" is tapped.
  final VoidCallback onMove;

  /// Callback when "Done" is tapped to exit selection mode.
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