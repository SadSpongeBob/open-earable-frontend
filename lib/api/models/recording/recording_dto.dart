
class RecordingDto {
  final String recordingId;
  final String name;
  final String? thumbnailUrl;
  final String videoTimestamp;
  final String? projectId;
  final String userId;
  final String uploadStatus; // PENDING/COMPLETED/FAILED

  RecordingDto({
    required this.recordingId,
    required this.name,
    this.thumbnailUrl,
    required this.videoTimestamp,
    this.projectId,
    required this.userId,
    required this.uploadStatus,
  });

  factory RecordingDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return RecordingDto(
      recordingId: data['recordingId'] as String,
      name: data['name'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      videoTimestamp: data['videoTimestamp'] as String,
      projectId: data['projectId'] as String?,
      userId: data['userId'] as String,
      uploadStatus: data['uploadStatus'] as String,
    );
  }
}
