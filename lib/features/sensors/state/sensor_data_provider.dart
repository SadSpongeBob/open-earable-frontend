import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/recordings/controllers/sensors_recording_controller.dart';

/// Provides live sensor data from an OpenEarable [Sensor] stream.
///
/// This provider:
/// - Listens to the sensor stream in real time
/// - Buffers recent values within a configurable time window
/// - Optionally forwards values to a [SensorsRecordingController]
///   for synchronized recording with video
/// - Throttles UI updates to avoid excessive rebuilds
///
/// The buffered [sensorValues] queue is trimmed continuously based
/// on the sensor timestamp and the configured [timeWindow].
/// 
/// Originally inspired by the OpenEarable sensor data handling logic,
/// but heavily modified to support:
/// - Rolling time window buffering
/// - Recording integration
/// - Throttled UI notifications

class SensorDataProvider with ChangeNotifier {
  /// The sensor whose data stream is being observed.
  final Sensor sensor;

  /// The size of the rolling time window used to retain recent values.
  ///
  /// Older values outside this window are removed from [sensorValues]
  /// to keep memory usage bounded and charts responsive.
  final int timeWindow;
  SensorsRecordingController? sensorsController;

  late final int _timestampCutoffMs;

  /// A queue containing the buffered sensor values within the current
  /// time window, ordered by arrival time.
  final Queue<SensorValue> sensorValues = Queue();

  StreamSubscription<SensorValue>? _sensorStreamSubscription;

  Timer? _throttleTimer;
  final Duration _throttleDuration = const Duration(milliseconds: 15);

  /// Creates a provider for streaming sensor data.
  ///
  /// [sensor] is the OpenEarable sensor whose stream will be listened to.
  /// [timeWindow] defines the amount of recent data (in sensor time units)
  /// kept in the internal buffer for visualization.
  /// [sensorsController], if provided, will receive live sensor values
  /// for recording alongside video.
  SensorDataProvider({
    required this.sensor,
    this.timeWindow = 5,
    this.sensorsController,
  }) {
    _timestampCutoffMs = (timeWindow * pow(10, -sensor.timestampExponent)).toInt();
    _listenToStream();
  }

  /// Subscribes to the sensor stream and processes incoming values.
  ///
  /// For each incoming [SensorValue]:
  /// - Adds it to the internal buffer
  /// - Forwards simplified values to the recording controller (if active)
  /// - Removes outdated values outside the configured time window
  /// - Triggers a throttled UI update
  void _listenToStream() {
    _sensorStreamSubscription = sensor.sensorStream.listen((sensorValue) {
      sensorValues.add(sensorValue);

      if (sensorsController != null) {
        // We convert the sensorValue to a simple list for JSON
        final values = sensorValue is SensorDoubleValue 
            ? sensorValue.values 
            : (sensorValue as SensorIntValue).values;
        
        sensorsController!.recordData(sensor.sensorName, values);
      }

    final cutoff = sensorValue.timestamp - _timestampCutoffMs;
    sensorValues.removeWhere((v) => v.timestamp < cutoff);

    _throttledNotifyListeners();
    });
  }

  /// Notifies listeners with a throttle to limit rebuild frequency.
  ///
  /// This prevents excessive UI updates when high-frequency sensor
  /// streams are received, improving performance and reducing jank.
  void _throttledNotifyListeners() {
    if (!hasListeners) return;

    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(_throttleDuration, () {
      if (hasListeners) notifyListeners();
    });
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _sensorStreamSubscription?.cancel();
    super.dispose();
  }
}
