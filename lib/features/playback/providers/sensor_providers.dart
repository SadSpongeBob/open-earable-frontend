import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_sample.dart';
import '../data/sensor_repository.dart';

final sensorDataProvider = FutureProvider<List<SensorSample>>((ref) async {
  return SensorRepository.loadFromFixedPath();
});
