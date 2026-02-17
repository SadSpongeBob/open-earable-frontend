import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/sensor_repository.dart';

final sensorDataProvider =
    FutureProvider.family<List<SensorSample>, String>((ref, key) async {
  return SensorRepository.loadFromFilePath(key);
});
