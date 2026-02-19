import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for reading and managing sensor data from local JSON files.
/// 
/// Timestamps are automatically adjusted relative to the first sample and
/// an additional `magicOffset` of 700ms is subtracted.
class SensorRepository {
  /// Loads sensor samples from a JSON file at [filePath].
  ///
  /// Returns a list of [SensorSample]s. If the file does not exist,
  /// is empty, or contains invalid data, an empty list is returned.
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
        return SensorSample(timestampMs: ts, x: dx, y: dy, z: dz);
      }).toList();
      if (samples.isEmpty) return [];
      final base = samples.first.timestampMs;
      const magicOffset = 700;
      return samples
          .map(
            (s) => SensorSample(
              timestampMs: s.timestampMs - base - magicOffset,
              x: s.x,
              y: s.y,
              z: s.z,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SensorRepository.loadFromFilePath failed: $e');
      }
      return [];
    }
  }

  /// Attempts to delete a temporary sensor file at [filePath].
  ///
  /// This is a "best effort" delete; errors are silently ignored.
  static Future<void> tryDeleteTempSensorFromPath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        file.delete();
      } catch (_) {
        // Best effort
      }
    }
  }
}

/// Riverpod provider to asynchronously load sensor samples from a file path.
final sensorSampleProvider = FutureProvider.family<List<SensorSample>, String>((
  ref,
  filePath,
) async {
  return SensorRepository.loadFromFilePath(filePath);
});

/// Represents a single sample from a sensor.
///
/// [timestampMs] – milliseconds since start (adjusted by first sample + offset).
/// [x], [y], [z] – sensor readings along each axis.
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
