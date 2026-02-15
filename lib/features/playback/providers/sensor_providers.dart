import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_sample.dart';
import '../data/sensor_repository.dart';

final sensorDataProvider = FutureProvider.family<List<SensorSample>, String>((ref, sensorType) async {
  return SensorRepository.loadFromFixedPath(sensorType);

});