import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/recording//recording_endpoints.dart';

class RecordingService {
  final Dio _dio;

  const RecordingService({required Dio dio}) : _dio = dio;

  Future<List<Recording>> getRecordings() async {
    final res = await _dio.get(RecordingEndpoints.baseUrl);
    final data = res.asList();

    return data.map((r) => Recording.fromJson(r)).toList();
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  return RecordingService(dio: dio);
});
