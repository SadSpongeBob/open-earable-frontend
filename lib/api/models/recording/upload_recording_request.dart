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
  final DateTime timestamp;

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
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

class SensorUpload {
  final int sensorIndex;
  final String name;
  final SensorType type;
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
    'type': type.json,
    'file': file.toJson(),
  };
}

enum SensorType {
  heartRate,
  thermometer;

  factory SensorType.fromString(String value) {
    return switch (value) {
      'HEART_RATE' => heartRate,
      'THERMOMETER' => thermometer,
      _ => throw ArgumentError.value(value, 'value', 'Invalid SensorType'),
    };
  }

  String get json {
    return switch (this) {
      SensorType.heartRate => 'HEART_RATE',
      SensorType.thermometer => 'THERMOMETER',
    };
  }
}

enum ContentType {
  mp4,
  webm,
  jpeg,
  png,
  json,
  binary;

  String get jsonRepresentation {
    return switch (this) {
      ContentType.mp4 => 'MP4',
      ContentType.webm => 'WEBM',
      ContentType.jpeg => 'JPEG',
      ContentType.png => 'PNG',
      ContentType.json => 'JSON',
      ContentType.binary => 'BINARY',
    };
  }
}
