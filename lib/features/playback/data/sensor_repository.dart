import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/sensor_sample.dart';

class SensorRepository {

  static Future<List<SensorSample>> loadFromFixedPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/sensor.json";
      final file = File(filePath);
      if (!await file.exists()) return [];

      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map || !decoded.containsKey('samples')) return [];

      final rawSamples = decoded['samples'];
      if (rawSamples is! List || rawSamples.isEmpty) return [];

      final accel = <SensorSample>[];
      for (final item in rawSamples) {
        if (item is! Map) continue;
        final tsRaw = item['timestampMs'];
        final values = item['values'];
        if (tsRaw == null || values is! Map) continue;
        final acc = values['Accelerometer'];
        if (acc is! List || acc.length < 3) continue;

        final ts = tsRaw is int ? tsRaw : (tsRaw is num ? tsRaw.toInt() : null);
        if (ts == null) continue;

        try {
          final dx = (acc[0] as num).toDouble();
          final dy = (acc[1] as num).toDouble();
          final dz = (acc[2] as num).toDouble();

          accel.add(SensorSample(timestampMs: ts, x: dx, y: dy, z: dz));
        } catch (_) {
          continue;
        }
      }

      if (accel.isEmpty) return [];

      final base = accel.first.timestampMs;
      return accel
          .map((s) => SensorSample(
                timestampMs: s.timestampMs - base,
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
