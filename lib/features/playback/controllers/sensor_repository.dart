import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SensorRepository {
  static Future<List<SensorSample>> loadFromFilePath(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);
      final rawData = decoded['data'] as List?;
      if (rawData == null) return [];
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
      const magicOffset = 700;
      return samples
          .map((s) => SensorSample(
                timestampMs: s.timestampMs - base - magicOffset,
                x: s.x,
                y: s.y,
                z: s.z,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('SensorRepository.loadFromFilePath failed: $e');
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
