import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import '../controllers/sensor_repository.dart';
class SensorRequest {
  final String projectId;
  final String recordingId;
  final String sensorId;

  const SensorRequest({
    required this.projectId,
    required this.recordingId,
    required this.sensorId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SensorRequest &&
            other.projectId == projectId &&
            other.recordingId == recordingId &&
            other.sensorId == sensorId;
  }

  @override
  int get hashCode => Object.hash(projectId, recordingId, sensorId);
}

final sensorDataProvider =
    FutureProvider.family<List<SensorSample>, SensorRequest>((ref, key) async {
  final localMedia = ref.read(localMediaProvider);
  return SensorRepository.loadFromLocalMedia(
      localMedia, key.projectId, key.recordingId, key.sensorId);
});