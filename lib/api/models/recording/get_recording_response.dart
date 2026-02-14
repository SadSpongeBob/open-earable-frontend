import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';

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
