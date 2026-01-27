
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
    return RecordingDto(
      recordingId: json['recordingId'] as String,
      name: json['name'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoTimestamp: json['videoTimestamp'] as String,
      projectId: json['projectId'] as String?,
      userId: json['userId'] as String,
      uploadStatus: json['uploadStatus'] as String,
    );
  }
}
