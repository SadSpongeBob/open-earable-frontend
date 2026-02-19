/// Represents a request to upload a recording along with associated sensor data.
///
/// Parameters:
/// - [name]: Name of the recording.
/// - [video]: The video file to upload as a [RecordingFile].
/// - [sensors]: List of associated [SensorUpload] objects. Defaults to empty.
/// - [projectId]: Optional project ID to associate the recording with.
/// - [thumbnailContent]: Optional content type of the thumbnail.
class UploadRecordingRequest {
  final String name;
  final RecordingFile video;
  final List<SensorUpload> sensors;
  final String? projectId;
  final ContentType? thumbnailContent;

  UploadRecordingRequest({
    required this.name,
    required this.video,
    this.sensors = const [],
    this.projectId,
    this.thumbnailContent,
  });

  /// Converts the request to JSON suitable for API submission.
  Map<String, dynamic> toJson() => {
    'name': name,
    'video': video.toJson(),
    'sensors': sensors.map((s) => s.toJson()).toList(),
    'projectId': projectId,
    'thumbnailContent': thumbnailContent?.jsonRepresentation,
  };
}

/// Represents a file associated with a recording (video or sensor).
///
/// Parameters:
/// - [filename]: Name of the file.
/// - [contentType]: Type of the file (video, image, JSON, etc.) as [ContentType].
/// - [sizeBytes]: File size in bytes.
/// - [timestamp]: Timestamp representing when the file was created.
class RecordingFile {
  final String filename;
  final ContentType contentType;
  final int sizeBytes;
  final DateTime timestamp;

  RecordingFile({
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.timestamp,
  });

  /// Converts the recording file to JSON for API submission.
  Map<String, dynamic> toJson() => {
    'filename': filename,
    'contentType': contentType.jsonRepresentation,
    'sizeBytes': sizeBytes,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

/// Represents a sensor upload associated with a recording.
///
/// Parameters:
/// - [sensorIndex]: Index of the sensor in the recording.
/// - [name]: Human-readable name of the sensor.
/// - [type]: Type of the sensor as [SensorType].
/// - [file]: The actual sensor file as [RecordingFile].
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

  /// Converts the sensor upload to JSON for API submission.
  Map<String, dynamic> toJson() => {
    'sensorIndex': sensorIndex,
    'name': name,
    'type': type.json,
    'file': file.toJson(),
  };
}

/// Enum representing deprecated sensor types.
/// 
/// This is currently not supported by the sensors library.
@Deprecated("Sensor type is not supported by sensors library")
enum SensorType {
  heartRate,
  thermometer, accelerometer;

  /// Creates a [SensorType] from a string (case-insensitive).
  factory SensorType.fromString(String value) {
    return switch (value.toUpperCase()) {
      'HEART_RATE' => heartRate,
      'THERMOMETER' => thermometer,
      'ACCELEROMETER' => accelerometer,
      _ => throw ArgumentError.value(value, 'value', 'Invalid SensorType'),
    };
  }

  /// Converts [SensorType] to string for API usage.
  String get json {
    return switch (this) {
      SensorType.heartRate => 'HEART_RATE',
      SensorType.thermometer => 'THERMOMETER',
      SensorType.accelerometer => 'ACCELEROMETER',
    };
  }
}

/// Enum representing file content types for recordings or sensor data.
///
/// Supported types: MP4, WEBM, JPEG, PNG, JSON, BINARY.
enum ContentType {
  mp4,
  webm,
  jpeg,
  png,
  json,
  binary;

  /// Creates a [ContentType] from a string (case-insensitive).
  factory ContentType.fromString(String value) {
    return switch (value) {
      'MP4' => mp4,
      'WEBM' => webm,
      'JPG' => jpeg,
      'JPEG' => jpeg,
      'PNG' => png,
      'JSON' => json,
      'BINARY' => binary,
      _ => throw ArgumentError.value(value, 'value', 'Invalid ContentType'),
    };
  }

  /// Converts [ContentType] to string for API usage.
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
