class SensorSample {
  final int timestampMs;
  final double x;
  final double y;
  final double z;

  const SensorSample({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'SensorSample(ts=$timestampMs, x=$x, y=$y, z=$z)';
}
