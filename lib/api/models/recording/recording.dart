import 'dart:io';

import 'package:flutter/cupertino.dart';

/// Represents a video recording with metadata, source information, and upload status.
///
/// Can represent recordings stored locally or in the cloud.
/// 
/// Parameters:
/// - [id]: Unique identifier for the recording.
/// - [name]: Name or title of the recording.
/// - [source]: Source of the recording (local or cloud).
/// - [thumbnailUrl]: URL of the thumbnail.
/// - [localThumbnailPath]: Local path to the thumbnail image (for local recordings).
/// - [localVideoPath]: Local file path to the video (for local recordings).
/// - [videoTimestamp]: Timestamp of the recording in UTC.
/// - [projectId]: Optional project ID this recording belongs to.
/// - [userId]: ID of the user who created/uploaded the recording.
/// - [uploadStatus]: Current upload status of the recording.
class Recording {
  final String id;
  final String name;

  final RecordingSource source;

  final String? thumbnailUrl;
  final String? localThumbnailPath;

  final String? localVideoPath;

  final DateTime videoTimestamp;
  final String? projectId;
  final String? userId;
  final UploadStatus uploadStatus;

  const Recording({
    required this.id,
    required this.name,
    required this.source,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.localVideoPath,
    required this.videoTimestamp,
    this.projectId,
    this.userId,
    required this.uploadStatus,
  });

  factory Recording.local({
    required String id,
    required String name,
    required String localVideoPath,
    required DateTime videoTimestamp,
    String? localThumbnailPath,
    String? projectId,
    UploadStatus uploadStatus = UploadStatus.pending,
  }) {
    return Recording(
      id: id,
      name: name,
      source: RecordingSource.local,
      localVideoPath: localVideoPath,
      localThumbnailPath: localThumbnailPath,
      videoTimestamp: videoTimestamp,
      projectId: projectId,
      uploadStatus: uploadStatus,
    );
  }

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
    id: json['recordingId'] as String,
    name: json['name'] as String,
    source: RecordingSource.cloud,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    videoTimestamp: DateTime.parse(json['videoTimestamp']).toUtc(),
    projectId: json['projectId'] as String?,
    userId: json['userId'] as String,
    uploadStatus: UploadStatus.fromString(json['uploadStatus']),
  );

  Recording copyWith({String? name, UploadStatus? uploadStatus}) {
    return Recording(
      id: id,
      name: name ?? this.name,
      source: source,
      thumbnailUrl: thumbnailUrl,
      videoTimestamp: videoTimestamp,
      projectId: projectId,
      userId: userId,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recording && other.id == id && other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, source);
}

/// Represents the current status of a recording upload.
enum UploadStatus {
  completed,
  failed,
  uploading,
  pending;

  factory UploadStatus.fromString(String value) {
    return switch (value) {
      'COMPLETED' => UploadStatus.completed,
      'PENDING' => UploadStatus.pending,
      'UPLOADING' => UploadStatus.uploading,
      'FAILED' => UploadStatus.failed,
      _ => throw ArgumentError.value(value, 'value', 'Invalid UploadStatus'),
    };
  }

  String get json => switch (this) {
    completed => 'COMPLETED',
    failed => 'FAILED',
    uploading => 'UPLOADING',
    pending => 'PENDING',
  };
}

/// Indicates whether a recording is stored locally or in the cloud.
enum RecordingSource { local, cloud }

/// Utility getters for [Recording].
extension RecordingX on Recording {
  bool get isLocal => source == RecordingSource.local;

  bool get isCloud => source == RecordingSource.cloud;

  bool get isUploading => uploadStatus == UploadStatus.uploading;

  bool get isUploaded => uploadStatus == UploadStatus.completed;

  bool get isUploadFailed => uploadStatus == UploadStatus.failed;

  ImageProvider get thumbnailProvider {
    if (localThumbnailPath != null) {
      return FileImage(File(localThumbnailPath!));
    }
    if (thumbnailUrl != null) {
      return NetworkImage(thumbnailUrl!);
    }
    return const AssetImage('assets/images/video_thumbnail.png');
  }
}
