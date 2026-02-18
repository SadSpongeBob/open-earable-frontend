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
