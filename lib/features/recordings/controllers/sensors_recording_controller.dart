import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SensorsRecordingController extends ChangeNotifier {
  bool isRecording = false;
  bool isPaused = false;

  int _recordingStartEpochMs = 0;

  final Map<int, Map<String, List<dynamic>>> _bucket = {};

  void recordData(String sensorId, List<dynamic> values) {
    if (!isRecording || isPaused) return;

    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;

    _bucket.putIfAbsent(nowEpochMs, () => {});
    _bucket[nowEpochMs]![sensorId] = values;
  }

  /// Call this at the SAME TIME as video start
  void startRecording() {
    isRecording = true;
    isPaused = false;
    _bucket.clear();

    _recordingStartEpochMs = DateTime.now().millisecondsSinceEpoch;

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
  Future<String> stopRecording({
    required int videoStartEpochMs,
    int? samplingRateHz,
  }) async {
    isRecording = false;
    isPaused = false;

    final Map<String, List<Map<String, dynamic>>> sensorsMap = {};

    for (var entry in _bucket.entries) {
      final timestamp = entry.key;
      final sensorValues = entry.value;

      for (var sensorId in sensorValues.keys) {
        final values = sensorValues[sensorId];
        sensorsMap.putIfAbsent(sensorId, () => []);

        final valueMap = <String, dynamic>{"timestamp": timestamp};
        final axisNames = ['x', 'y', 'z', 'w', 'v', 'u', 't']; 

        // map values to x, y, z
        if (values != null) {
          for (int i = 0; i < values.length; i++) {
            final axis = i < axisNames.length ? axisNames[i] : 'axis$i';
            valueMap[axis] = values[i];
          }
        }

        sensorsMap[sensorId]!.add(valueMap);
      }
    }

    final sensorsList = sensorsMap.entries.map((e) {
      return {
        "name": e.key,
        "values": e.value,
      };
    }).toList();

    final json = {
      "version": 1,
      "recording": {
        "startTimeEpochMs": _recordingStartEpochMs,
        ...?samplingRateHz != null ? {"samplingRateHz": samplingRateHz} : null,
      },
      "video": {
        "startTimeEpochMs": videoStartEpochMs,
      },
      "sensors": sensorsList,
    };

    final dir = Directory('/storage/emulated/0/OpenEarable/sensors');
    await dir.create(recursive: true);
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.json';
    await File(path).writeAsString(jsonEncode(json));

    return path;
  }
}
