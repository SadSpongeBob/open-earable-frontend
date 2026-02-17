import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/app/utils/helpers.dart';

class SensorsRecordingController extends ChangeNotifier {
  bool isRecording = false;
  bool isPaused = false;

  final Map<int, Map<String, List<dynamic>>> _bucket = {};

  void recordData(String sensorId, List<dynamic> values) {
    if (!isRecording || isPaused) return;

    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;

    _bucket.putIfAbsent(nowEpochMs, () => {});
    _bucket[nowEpochMs]![sensorId] = values;
  }

  /// Call this at the SAME TIME as video start
  Future<void> startRecording() async {
    isRecording = true;
    isPaused = false;
    _bucket.clear();

    notifyListeners();
  }

  /// Call together with video pause
  void pauseRecording() {
    if (!isRecording || isPaused) return;
    isPaused = true;
    notifyListeners();
  }

  /// Call together with video resume
  void resumeRecording() {
    if (!isRecording || !isPaused) return;
    isPaused = false;
    notifyListeners();
  }

  /// Call when video stops
  Future<void> stopRecording({
    required DateTime videoStart,
    required String recordingId,
    required String projectId,
    required WidgetRef ref,
  }) async {
    isRecording = false;
    isPaused = false;
    final media = ref.read(localMediaProvider);
    final dir = media.recordingDir(projectId, recordingId);
    await dir.create(recursive: true);
    final Map<String, List<Map<String, dynamic>>> sensorsMap = {};
    for (var entry in _bucket.entries) {
      final timestamp = entry.key;
      final sensorValues = entry.value;
      for (var sensorId in sensorValues.keys) {
        final values = sensorValues[sensorId];
        sensorsMap.putIfAbsent(sensorId, () => []);
        final valueMap = <String, dynamic>{
          "timestamp": timestamp,
        };
        if (values != null) {
          for (int i = 0; i < values.length; i++) {
            valueMap["axis$i"] = values[i];
          }
        }
        sensorsMap[sensorId]!.add(valueMap);
      }
    }
    final int startEpoch = videoStart.millisecondsSinceEpoch;
    for (final entry in sensorsMap.entries) {
      final sensorName = entry.key;
      final dataList = entry.value;
      final generatedSensorId = Helpers.getSensorDataId();
      final jsonMap = {
        "sourceName": sensorName,
        "startEpochMs": startEpoch,
        "data": dataList,
      };

      final file = media.reccordingSensors(
        projectId,
        recordingId,
        generatedSensorId,
      );
      await file.writeAsString(
        const JsonEncoder.withIndent("  ").convert(jsonMap),
      );
    }
  }
}
