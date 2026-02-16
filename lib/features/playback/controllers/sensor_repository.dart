import 'dart:convert';
import 'dart:io';
class SensorRepository {
  static Future<List<SensorSample>> loadFromFile(String sensortype) async {
    try {
      final filePath =
          "/data/user/0/com.openearable.openearable/app_flutter/OpenEarable/prj_69925de7611f964e58272fbd/rcd_1f10b5a6-fd1f-6930-9903-fd7cc8487d2c/Accelerometer.json";
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);
      final rawData = decoded['data'] as List;
      final samples = rawData.map((item) {
        final ts = (item['timestamp'] as num).toInt();
        final dx = (item['axis0'] as num).toDouble();
        final dy = (item['axis1'] as num).toDouble();
        final dz = (item['axis2'] as num).toDouble();
        return SensorSample(
          timestampMs: ts,
          x: dx,
          y: dy,
          z: dz,
        );
      }).toList();
      if (samples.isEmpty) return [];
      final base = samples.first.timestampMs;
      ///TODO -700 is a magic number to align the sensor data with the video, need to find a better solution for this
      return samples
          .map((s) => SensorSample(
        timestampMs: s.timestampMs - base - 700,
        x: s.x,
        y: s.y,
        z: s.z,
      ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

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
