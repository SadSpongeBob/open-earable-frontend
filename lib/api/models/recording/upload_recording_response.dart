import 'package:openearable/api/models/recording/upload_recording_request.dart';

class UploadRecordingResponse {
  final String recordingId;
  final String name;
  final String? projectId;
  final UploadInfo videoUpload;
  final List<SensorUploadInfo> sensorUploads;
  final ThumbnailUploadInfo? thumbnailUpload;

  UploadRecordingResponse({
    required this.recordingId,
    required this.name,
    this.projectId,
    required this.videoUpload,
    required this.sensorUploads,
    this.thumbnailUpload,
  });

  factory UploadRecordingResponse.fromJson(Map<String, dynamic> json) {
    final recordingId = json['recordingId'] as String;
    final name = json['name'] as String;
    final projectId = json['projectId'] as String?;

    final videoUpload = UploadInfo.fromJson(
      json['videoUpload'] as Map<String, dynamic>,
    );

    final sensorUploads = (json['sensorUploads'] as List)
        .map((e) => SensorUploadInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    final thumbnailRaw = json['thumbnailUpload'] as Map<String, dynamic>?;
    final thumbnailUpload = thumbnailRaw != null
        ? ThumbnailUploadInfo.fromJson(thumbnailRaw)
        : null;

    return UploadRecordingResponse(
      recordingId: recordingId,
      name: name,
      projectId: projectId,
      videoUpload: videoUpload,
      sensorUploads: sensorUploads,
      thumbnailUpload: thumbnailUpload,
    );
  }
}

class UploadInfo {
  final String filename;
  final String key;
  final String uploadUrl;
  final DateTime timestamp;
  final Map<String, String> requiredHeaders;

  UploadInfo({
    required this.filename,
    required this.key,
    required this.uploadUrl,
    required this.timestamp,
    required this.requiredHeaders,
  });

  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    final filename = json['filename'] as String;
    final key = json['key'] as String;
    final uploadUrl = json['uploadUrl'] as String;
    final timestamp = DateTime.parse(json['timestamp']).toUtc();
    final headers = (json['requiredHeaders'] as Map<String, dynamic>)
        .cast<String, String>();

    return UploadInfo(
      filename: filename,
      key: key,
      uploadUrl: uploadUrl,
      timestamp: timestamp,
      requiredHeaders: headers,
    );
  }
}

class SensorUploadInfo {
  final String sensorId;
  final int sensorIndex;
  final String name;
  final UploadInfo sensor;
  final SensorType type;

  SensorUploadInfo({
    required this.sensorId,
    required this.sensorIndex,
    required this.name,
    required this.sensor,
    required this.type,
  });

  factory SensorUploadInfo.fromJson(Map<String, dynamic> json) {
    final sensorId = json['sensorId'] as String;
    final sensorIndex = json['sensorIndex'] as int;
    final name = json['name'] as String;
    final type = SensorType.fromString(json['sensorType'] as String);
    final sensor = UploadInfo.fromJson(json['sensor'] as Map<String, dynamic>);

    return SensorUploadInfo(
      sensorId: sensorId,
      sensorIndex: sensorIndex,
      name: name,
      sensor: sensor,
      type: type,
    );
  }
}

class ThumbnailUploadInfo {
  final String uploadUrl;
  final Map<String, String> requiredHeaders;

  ThumbnailUploadInfo({required this.uploadUrl, required this.requiredHeaders});

  factory ThumbnailUploadInfo.fromJson(Map<String, dynamic> json) {
    return ThumbnailUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      requiredHeaders: (json['requiredHeaders'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  }
}
