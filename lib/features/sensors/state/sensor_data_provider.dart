import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/recordings/controllers/sensors_recording_controller.dart';

class SensorDataProvider with ChangeNotifier {
  final Sensor sensor;
  final int timeWindow;
  SensorsRecordingController? sensorsController;

  late final int _timestampCutoffMs;
  final Queue<SensorValue> sensorValues = Queue();

  StreamSubscription<SensorValue>? _sensorStreamSubscription;

  Timer? _throttleTimer;
  final Duration _throttleDuration = const Duration(milliseconds: 15);

  SensorDataProvider({
    required this.sensor,
    this.timeWindow = 5,
    this.sensorsController,
  }) {
    _timestampCutoffMs = (timeWindow * pow(10, -sensor.timestampExponent)).toInt();
    _listenToStream();
  }

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

  void _throttledNotifyListeners() {
    if (!hasListeners) return;

    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(_throttleDuration, notifyListeners);
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _sensorStreamSubscription?.cancel();
    super.dispose();
  }
}
