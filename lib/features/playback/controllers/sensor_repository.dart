import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class SensorRepository {
  /// Lädt SensorSamples von einer JSON-Datei in der neuen Struktur
  /// sensortype z.B. "Accelerometer", "Gyroscope", etc.
  static Future<List<SensorSample>> loadFromFile(String sensortype) async {
    try {
      // Pfad zum OpenEarable Recording
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          "/data/user/0/com.openearable.openearable/app_flutter/OpenEarable/prj_69925de7611f964e58272fbd/test/Gyroscope.json";
      final file = File(filePath);

      debugPrint("📂 Prüfe Datei: $filePath");

      if (!await file.exists()) {
        debugPrint("❌ Datei existiert nicht!");
        return [];
      }

      final jsonString = await file.readAsString();
      debugPrint("✅ JSON geladen, Länge: ${jsonString.length} Zeichen");

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        debugPrint("❌ JSON ist keine Map");
        return [];
      }

      if (!decoded.containsKey('data')) {
        debugPrint("❌ JSON enthält kein 'data'-Feld");
        return [];
      }

      final rawData = decoded['data'];
      if (rawData is! List || rawData.isEmpty) {
        debugPrint("❌ 'data' ist keine Liste oder leer");
        return [];
      }

      debugPrint("✅ ${rawData.length} Roh-Samples gefunden");

      final samples = <SensorSample>[];
      for (final item in rawData) {
        if (item is! Map) continue;

        final tsRaw = item['timestamp'];
        if (tsRaw == null) continue;

        final ts = tsRaw is int
            ? tsRaw
            : (tsRaw is num ? tsRaw.toInt() : null);
        if (ts == null) continue;

        try {
          final dx = (item['axis0'] as num?)?.toDouble() ?? 0;
          final dy = (item['axis1'] as num?)?.toDouble() ?? 0;
          final dz = (item['axis2'] as num?)?.toDouble() ?? 0;

          samples.add(SensorSample(timestampMs: ts, x: dx, y: dy, z: dz));
        } catch (e) {
          debugPrint("⚠ Fehler beim Parsen eines Samples: $e");
        }
      }

      debugPrint("✅ ${samples.length} Samples erfolgreich geladen");

      if (samples.isEmpty) return [];

      // Optional: Zeit auf 0 setzen
      final base = samples.first.timestampMs;
      final normalized = samples
          .map((s) => SensorSample(
        timestampMs: s.timestampMs - base-700, // 50ms vor dem ersten Sample starten
        x: s.x,
        y: s.y,
        z: s.z,
      ))
          .toList();

      debugPrint("✅ Timestamps auf 0 gesetzt (Basis: $base)");

      return normalized;
    } catch (e) {
      debugPrint("❌ Exception beim Laden der Datei: $e");
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
