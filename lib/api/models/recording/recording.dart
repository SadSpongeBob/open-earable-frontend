class Recording {
  final String recordingId;
  final String name;
  final String? thumbnailUrl;
  final DateTime videoTimestamp;
  final String? projectId;
  final String userId;
  final UploadStatus uploadStatus; // PENDING/COMPLETED/FAILED

  Recording({
    required this.recordingId,
    required this.name,
    this.thumbnailUrl,
    required this.videoTimestamp,
    this.projectId,
    required this.userId,
    required this.uploadStatus,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      recordingId: json['recordingId'] as String,
      name: json['name'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoTimestamp: DateTime.parse(json['videoTimestamp']).toUtc(),
      projectId: json['projectId'] as String?,
      userId: json['userId'] as String,
      uploadStatus: UploadStatus.fromString(json['uploadStatus']),
    );
  }
}
enum UploadStatus {
  completed,
  failed,
  pending;

  factory UploadStatus.fromString(String value) {
    return switch (value) {
      'COMPLETED' => UploadStatus.completed,
      'PENDING' => UploadStatus.pending,
      'FAILED' => UploadStatus.failed,
      _ => throw ArgumentError.value(value, 'value', 'Invalid UploadStatus'),
    };
  }
}
