import 'package:openearable/api/models/recording/upload_recording_request.dart';

class Sensor {
  final int sensorIndex;
  final String sensorId;
  final String name;
  final DateTime timeStamp;
  final SensorType sensorType;
  final String localPath;

  Sensor({
    required this.sensorIndex,
    required this.sensorId,
    required this.name,
    required this.timeStamp,
    required this.sensorType,
    required this.localPath,
  });
}
