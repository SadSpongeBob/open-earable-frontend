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

    final samples = _bucket.entries
      .map((e) => {
            "timestampMs": e.key,
            "values": e.value,
          })
      .toList()
    ..sort((a, b) => (a["timestampMs"] as int).compareTo(b["timestampMs"] as int));

    final json = {
      "version": 1,
      "recording": {
        "startTimeEpochMs": _recordingStartEpochMs,
        if (samplingRateHz != null) "samplingRateHz": samplingRateHz,
      },
      "video": {
        "startTimeEpochMs": videoStartEpochMs,
      },
      "samples": samples,
    };

    final dir = Directory('/storage/emulated/0/OpenEarable/sensors');
    await dir.create(recursive: true);
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.json';
    await File(path).writeAsString(jsonEncode(json));

    return path;
  }
}
