import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SensorsRecordingController extends ChangeNotifier {
  bool isRecording = false;
  bool isPaused = false;

  int _recordingStartEpochMs = 0;
  int _pausedAccumulatedMs = 0;
  int _pauseStartEpochMs = 0;

  final Map<int, Map<String, List<dynamic>>> _bucket = {};

  void recordData(String sensorId, List<dynamic> values) {
    if (!isRecording || isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final t = now - _recordingStartEpochMs - _pausedAccumulatedMs;

    _bucket.putIfAbsent(t, () => {});
    _bucket[t]![sensorId] = values;
  }

  /// Call this at the SAME TIME as video start
  void startRecording() {
    isRecording = true;
    isPaused = false;
    _bucket.clear();

    _recordingStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    _pausedAccumulatedMs = 0;

    notifyListeners();
  }

  /// Call together with video pause
  void pauseRecording() {
    if (!isRecording || isPaused) return;
    isPaused = true;
    _pauseStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// Call together with video resume
  void resumeRecording() {
    if (!isRecording || !isPaused) return;
    isPaused = false;
    _pausedAccumulatedMs +=
        DateTime.now().millisecondsSinceEpoch - _pauseStartEpochMs;
    notifyListeners();
  }

  /// Call when video stops
  Future<String> stopRecording() async {
    isRecording = false;
    isPaused = false;

    final samples = _bucket.entries
      .map((e) => {
            "t": e.key,
            "values": e.value,
          })
      .toList()
    ..sort((a, b) => (a["t"] as int).compareTo(b["t"] as int));

    final json = {
      "version": 1,
      "startTimeEpochMs": _recordingStartEpochMs,
      "samples": samples,
    };

    final dir = Directory('/storage/emulated/0/OpenEarable/sensors');
    await dir.create(recursive: true);
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.json';
    await File(path).writeAsString(jsonEncode(json));

    return path;
  }
}
