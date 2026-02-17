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
}
