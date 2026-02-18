import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// Bottom action bar displayed in project selection mode.
///
/// Shows bulk actions (Delete, Duplicate, Rename) based on the number
/// of selected projects and a Done button to exit selection mode.
class ProjectSelectionActionBar extends StatelessWidget {
  const ProjectSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
    required this.onDone,
  });

  /// Number of currently selected projects.
  final int selectedCount;

  /// Called when the Delete action is pressed.
  final VoidCallback onDelete;

  /// Called when the Duplicate action is pressed.
  final VoidCallback onDuplicate;

  /// Called when the Rename action is pressed 
  /// (only visible when one project is selected).
  final VoidCallback onRename;

  /// Called when the Done button is pressed to exit selection mode.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final showRename = selectedCount == 1;

    return Container(
      height: 52,
      color: AppColors.fifty,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          TextButton(
            onPressed: selectedCount == 0 ? null : onDelete,
            child: Text(
              'Delete',
              style: AppTextStyles.footerBold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          TextButton(
            onPressed: selectedCount == 0 ? null : onDuplicate,
            child: const Text(
              'Duplicate',
              style: AppTextStyles.footerMedium,
            ),
          ),

          if (showRename) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRename,
              child: const Text(
                'Rename',
                style: AppTextStyles.footerMedium,
              ),
            ),
          ],

          const Spacer(),

          TextButton(
            onPressed: onDone,
            child: const Text(
              'Done',
              style: AppTextStyles.footerMedium,
            ),
          ),
        ],
      ),
    );
  }
}
