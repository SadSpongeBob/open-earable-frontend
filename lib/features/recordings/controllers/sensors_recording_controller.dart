import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/app/utils/helpers.dart';

/// Manages sensor data collection for a recording session.
///
/// Properties:
/// - [isRecording]: Whether recording is active.
/// - [isPaused]: Whether recording is currently paused.
/// - [_bucket]: Internal storage for sensor readings, keyed by timestamp and sensor ID.
class SensorsRecordingController extends ChangeNotifier {
  bool isRecording = false;
  bool isPaused = false;

  final Map<int, Map<String, List<dynamic>>> _bucket = {};

  /// Records sensor data at the current timestamp.
  ///
  /// - Adds the sensor readings to the internal [_bucket] only if [isRecording] is true and [isPaused] is false.
  /// - Timestamp is taken in milliseconds since epoch.
  /// 
  /// Parameters:
  /// - [sensorId]: Unique identifier of the sensor (e.g., "accelerometer").
  /// - [values]: List of numeric sensor readings (e.g., [x, y, z] axes).
  void recordData(String sensorId, List<dynamic> values) {
    if (!isRecording || isPaused) return;

    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;

    _bucket.putIfAbsent(nowEpochMs, () => {});
    _bucket[nowEpochMs]![sensorId] = values;
  }
  /// Starts a new sensor recording session.
  ///
  /// - Clears any previous data in [_bucket].
  /// - Sets [isRecording] to true and [isPaused] to false.
  /// - Notifies listeners for UI updates.
  ///
  /// Note:
  /// - Call this at the SAME TIME as video start
  Future<void> startRecording() async {
    isRecording = true;
    isPaused = false;
    _bucket.clear();

    notifyListeners();
  }

  /// Pauses sensor data collection.
  ///
  /// - Sets [isPaused] to true.
  /// - No data will be recorded until [resumeRecording] is called.
  /// - Notifies listeners for UI updates.
  ///
  /// Note:
  /// - Call together with video pause
  void pauseRecording() {
    if (!isRecording || isPaused) return;
    isPaused = true;
    notifyListeners();
  }

  /// Resumes sensor data collection after a pause.
  ///
  /// - Sets [isPaused] to false.
  /// - Notifies listeners for UI updates.
  ///
  /// Note:
  /// - Call together with video resume
  void resumeRecording() {
    if (!isRecording || !isPaused) return;
    isPaused = false;
    notifyListeners();
  }

  /// Stops sensor recording and writes data to local storage.
  ///
  /// - Sets [isRecording] and [isPaused] to false.
  /// - Aggregates sensor readings from [_bucket] and groups them by sensor ID.
  /// - Creates a JSON file for each sensor under the project/recording directory.
  /// - Each JSON includes:
  ///   - sourceName`: Sensor ID
  ///   - `startEpochMs`: Video start timestamp in milliseconds
  ///   - `data`: List of timestamped sensor readings (axis0, axis1, ...)
  ///
  /// Parameters:
  /// - [videoStart]: Timestamp of when video recording started.
  /// - [recordingId]: Unique ID of the recording session.
  /// - [projectId]: ID of the project where recording belongs.
  /// - [ref]: WidgetRef used to access [localMediaProvider] for file storage.
  ///
  /// Note:
  /// - Call when video stops
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

      final file = media.recordingSensors(
        projectId,
        recordingId,
        generatedSensorId,
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent("  ").convert(jsonMap),
      );
    }
  }
}
