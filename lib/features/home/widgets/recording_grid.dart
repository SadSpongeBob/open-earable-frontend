import 'package:flutter/material.dart';
import 'package:openearable/api/models/recording/recording.dart';

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
  });

  final String name;
  final bool showSelectionCircle;
  final bool isChecked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ImageProvider thumbnail;

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
                          border: Border.all(color: Colors.grey.shade600),
                          image: DecorationImage(
                            image: thumbnail,
                            fit: BoxFit.cover,
                          ),
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
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
        border: Border.all(width: 2, color: Colors.white),
        color: isChecked ? (Colors.grey.shade900) : Colors.transparent,
      ),
      child: isChecked
          ? const Center(
              child: Icon(Icons.check, size: 30, color: Colors.white),
            )
          : null,
    );
  }
}
