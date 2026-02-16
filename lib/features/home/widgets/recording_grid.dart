import 'package:flutter/material.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

class RecordingGrid extends StatelessWidget {
  const RecordingGrid({
    super.key,
    required this.recordings,
    required this.isSelectionMode,
    required this.selectedRecordingIds,
    this.onTapRecording,
    this.onLongPressRecording,
  });

  final List<Recording> recordings;

  final bool isSelectionMode;
  final Set<String> selectedRecordingIds;

  final ValueChanged<Recording>? onTapRecording;
  final ValueChanged<Recording>? onLongPressRecording;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 630),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 180,
              ),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                final isChecked = selectedRecordingIds.contains(recording.id);
                return _RecordingTile(
                  name: recording.name,
                  showSelectionCircle: isSelectionMode,
                  isChecked: isChecked,
                  onTap: () => onTapRecording?.call(recording),
                  onLongPress: () => onLongPressRecording?.call(recording),
                  thumbnail: recording.thumbnailProvider,
                  isUploading: recording.isUploading,
                  isUploaded: recording.isUploaded,
                  isUploadFailed: recording.isUploadFailed,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.name,
    required this.showSelectionCircle,
    required this.isChecked,
    required this.onTap,
    required this.onLongPress,
    required this.thumbnail,
    required this.isUploading,
    required this.isUploaded,
    required this.isUploadFailed,
  });

  final String name;
  final bool showSelectionCircle;
  final bool isChecked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ImageProvider thumbnail;
  final bool isUploading;
  final bool isUploaded;
  final bool isUploadFailed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sixHundred),
                          image: DecorationImage(
                            image: thumbnail,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      if (isUploading || isUploaded || isUploadFailed)
                        Positioned(
                          top: 6,
                          left: 14,
                          child: _UploadStatusIndicator(
                            isUploading: isUploading,
                            isUploaded: isUploaded,
                            isUploadFailed: isUploadFailed,
                          ),
                        ),

                      if (showSelectionCircle)
                        _SelectionCircle(isChecked: isChecked),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.footerBold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: AppColors.sevenHundred),
        color: isChecked ? (AppColors.sevenHundred) : Colors.transparent,
      ),
      child: isChecked
          ? const Center(
              child: Icon(Icons.check, size: 30, color: AppColors.fifty),
            )
          : null,
    );
  }
}

class _UploadStatusIndicator extends StatelessWidget {
  const _UploadStatusIndicator({
    required this.isUploading,
    required this.isUploaded,
    required this.isUploadFailed,
  });

  final bool isUploading;
  final bool isUploaded;
  final bool isUploadFailed;

  @override
  Widget build(BuildContext context) {
    Widget icon;

    if (isUploading) {
      icon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
      );
    } else if (isUploaded) {
      icon = const Icon(Icons.check_circle, color: AppColors.green, size: 22);
    } else if (isUploadFailed) {
      icon = const Icon(Icons.error, color: AppColors.primary, size: 22);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: icon,
    );
  }
}
