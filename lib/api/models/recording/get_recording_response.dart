import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';

/// Represents the full response returned when fetching a recording from the server.
///
/// Contains metadata about the recording, associated sensors, the project it belongs to,
/// the uploading user, and upload status.
/// 
/// Parameters:
/// - [recordingId]: Unique identifier for the recording.
/// - [name]: Display name of the recording.
/// - [videoUrl]: URL to the recording video.
/// - [videoTimestamp]: Timestamp of the recording video in UTC.
/// - [sensors]: List of sensors attached to the recording.
/// - [projectId]: Optional ID of the project this recording belongs to.
/// - [userId]: ID of the user who created/uploaded the recording.
/// - [uploadStatus]: Upload status of the recording.
class GetRecordingResponse {
  final String recordingId;
  final String name;
  final String videoUrl;
  final DateTime videoTimestamp;
  final List<GetSensorResponse> sensors;
  final String? projectId;
  final String userId;
  final UploadStatus uploadStatus;

  GetRecordingResponse({
    required this.recordingId,
    required this.name,
    required this.videoUrl,
    required this.videoTimestamp,
    required this.sensors,
    required this.projectId,
    required this.userId,
    required this.uploadStatus,
  });

  factory GetRecordingResponse.fromJson(Map<String, dynamic> json) {
    final sensors = (json['sensors'] as List)
        .map((e) => GetSensorResponse.fromJson(e as Map<String, dynamic>))
        .toList();

    return GetRecordingResponse(
      recordingId: json['recordingId'] as String,
      name: json['name'] as String,
      videoUrl: json['videoUrl'] as String,
      videoTimestamp: DateTime.parse(json['videoTimestamp']).toUtc(),
      sensors: sensors,
      projectId: json['projectId'] as String?,
      userId: json['userId'] as String,
      uploadStatus: UploadStatus.fromString(json['uploadStatus'] as String),
    );
  }
}

/// Represents metadata for a sensor associated with a recording.
///
/// Includes the sensor's ID, type, name, URL for data access, index, and timestamp.
/// 
/// Parameters:
/// - [sensorId]: Unique identifier for the sensor.
/// - [sensorIndex]: Index of the sensor in the recording.
/// - [name]: Display name of the sensor.
/// - [url]: URL to the sensor data file.
/// - [type]: Type of the sensor.
/// - [timestamp]: Timestamp of the sensor data in UTC.
class GetSensorResponse {
  final String sensorId;
  final int sensorIndex;
  final String name;
  final String url;
  final SensorType type;
  final DateTime timestamp;

  GetSensorResponse({
    required this.sensorId,
    required this.sensorIndex,
    required this.name,
    required this.url,
    required this.type,
    required this.timestamp,
  });

  factory GetSensorResponse.fromJson(Map<String, dynamic> json) {
    return GetSensorResponse(
      sensorId: json['sensorId'] as String,
      sensorIndex: json['sensorIndex'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      type: SensorType.fromString(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp']).toUtc(),
    );
  }
}
