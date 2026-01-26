
class UploadRecordingRequest {
  final String name;
  final RecordingFile video;
  final List<SensorUpload> sensors;
  final String? projectId;
  final String? thumbnailContent;

  UploadRecordingRequest({
    required this.name,
    required this.video,
    this.sensors = const [],
    this.projectId,
    this.thumbnailContent,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'video': video.toJson(),
        'sensors': sensors.map((s) => s.toJson()).toList(),
        'projectId': projectId,
        'thumbnailContent': thumbnailContent,
      };
}

class RecordingFile {
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String timestamp;

  RecordingFile({
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'timestamp': timestamp,
      };
}

class SensorUpload {
  final int sensorIndex;
  final String name;
  final String type;
  final RecordingFile file;

  SensorUpload({
    required this.sensorIndex,
    required this.name,
    required this.type,
    required this.file,
  });

  Map<String, dynamic> toJson() => {
        'sensorIndex': sensorIndex,
        'name': name,
        'type': type,
        'file': file.toJson(),
      };
}
