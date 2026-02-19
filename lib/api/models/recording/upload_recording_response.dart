import 'package:openearable/api/models/recording/upload_recording_request.dart';

/// Represents the response returned from the server after a recording upload.
///
/// Contains information about the uploaded recording, its associated sensors,
/// and optional thumbnail upload info.
///
/// Parameters:
/// - [recordingId]: Unique identifier of the uploaded recording.
/// - [name]: Name of the recording.
/// - [projectId]: Optional project ID associated with the recording.
/// - [videoUpload]: Upload information for the main video file.
/// - [sensorUploads]: List of upload information for associated sensors.
/// - [thumbnailUpload]: Optional upload information for the recording's thumbnail.
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

  /// Creates an [UploadRecordingResponse] from a JSON map returned by the API.
  factory UploadRecordingResponse.fromJson(Map<String, dynamic> json) {
    final recordingId = json['recordingId'] as String;
    final name = json['name'] as String;
    final projectId = json['projectId'] as String?;

    final videoUpload = UploadInfo.fromJson(
      json['videoUpload'] as Map<String, dynamic>,
    );

    final sensorUploadsRaw = json['sensorUploads'] as List<dynamic>;
    final sensorUploads = (sensorUploadsRaw)
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

/// Represents information required to upload a file to the server.
///
/// Parameters:
/// - [filename]: Name of the file.
/// - [key]: Key or identifier used for the upload.
/// - [uploadUrl]: URL to which the file should be uploaded.
/// - [timestamp]: Timestamp when the upload info was generated.
/// - [requiredHeaders]: Any HTTP headers required for the upload request.
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

  /// Creates an [UploadInfo] object from JSON returned by the API.
  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    final filename = json['filename'] as String;
    final key = json['key'] as String;
    final uploadUrl = json['uploadUrl'] as String;

    final tsRaw = json['timestamp'] as String;
    final timestamp = DateTime.parse(tsRaw).toUtc();

    final headers = Map<String, String>.from(json['requiredHeaders'] as Map);

    return UploadInfo(
      filename: filename,
      key: key,
      uploadUrl: uploadUrl,
      timestamp: timestamp,
      requiredHeaders: headers,
    );
  }
}

/// Represents information for uploading a single sensor associated with a recording.
///
/// Parameters:
/// - [sensorId]: Unique identifier of the sensor.
/// - [sensorIndex]: Index of the sensor in the recording.
/// - [name]: Human-readable name of the sensor.
/// - [sensor]: Upload info for the sensor file.
/// - [type]: Type of the sensor as [SensorType].
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

  /// Creates a [SensorUploadInfo] object from JSON returned by the API.
  factory SensorUploadInfo.fromJson(Map<String, dynamic> json) {
    final sensorId = json['sensorId'] as String;
    final sensorIndex = json['sensorIndex'] as int;
    final name = json['name'] as String;

    final typeRaw = json['type'] as String;
    SensorType type;
    try {
      type = SensorType.fromString(typeRaw);
    } catch (_) {
      type = SensorType.heartRate;
    }

    final sensorJson = json['sensor'] as Map<String, dynamic>;

    final sensor = UploadInfo.fromJson(sensorJson);

    return SensorUploadInfo(
      sensorId: sensorId,
      sensorIndex: sensorIndex,
      name: name,
      sensor: sensor,
      type: type,
    );
  }
}

/// Represents upload information for a recording thumbnail.
///
/// Parameters:
/// - [uploadUrl]: URL to which the thumbnail should be uploaded.
/// - [requiredHeaders]: HTTP headers required for the upload request.
class ThumbnailUploadInfo {
  final String uploadUrl;
  final Map<String, String> requiredHeaders;

  ThumbnailUploadInfo({required this.uploadUrl, required this.requiredHeaders});

  /// Creates a [ThumbnailUploadInfo] object from JSON returned by the API.
  factory ThumbnailUploadInfo.fromJson(Map<String, dynamic> json) {
    return ThumbnailUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      requiredHeaders: Map<String, String>.from(json['requiredHeaders'] as Map),
    );
  }
}
