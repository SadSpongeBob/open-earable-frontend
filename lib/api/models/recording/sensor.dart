/// Represents a sensor associated with a recording, including its metadata
/// and local storage path.
/// 
/// Parameters:
/// - [sensorIndex]: The index of the sensor in the recording.
/// - [sensorId]: Unique identifier for the sensor.
/// - [name]: Human-readable name of the sensor (e.g., "Accelerometer").
/// - [timeStamp]: Timestamp when the sensor data was recorded.
/// - [localPath]: Local file path where the sensor data is stored.
class Sensor {
  final int sensorIndex;
  final String sensorId;
  final String name;
  final DateTime timeStamp;
  final String localPath;

  Sensor({
    required this.sensorIndex,
    required this.sensorId,
    required this.name,
    required this.timeStamp,
    required this.localPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sensor &&
          runtimeType == other.runtimeType &&
          sensorId == other.sensorId;

  @override
  int get hashCode => sensorId.hashCode;
}
