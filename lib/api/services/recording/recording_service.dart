import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/recording/upload_recording_request.dart';
import '../../models/recording/upload_recording_response.dart';
import '../../models/recording/recording_dto.dart';
import 'recording_endpoints.dart';

class RecordingService {
  final Dio dioClient;

  RecordingService({required this.dioClient});

  Dio get dio => dioClient;

  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) async {
    final res = await dioClient.post(
      RecordingEndpoints.startUpload,
      data: req.toJson(),
      options: Options(validateStatus: (status) => true),
    );
    final raw = res.data;
    if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
      throw Exception('startUpload failed: status=${res.statusCode} body=${raw}');
    }
    if (raw is Map<String, dynamic>) {
      return UploadRecordingResponse.fromJson(raw.containsKey('data') ? raw : {'data': raw});
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return UploadRecordingResponse.fromJson(decoded.containsKey('data') ? decoded : {'data': decoded});
      } catch (_) {
        throw Exception('startUpload: Failed to decode response string');
      }
    }
    throw Exception('startUpload: unexpected response shape: ${raw.runtimeType}');
  }
  Future<RecordingDto?> completeUpload(String recordingId) async {
    final res = await dioClient.put(
      RecordingEndpoints.complete(recordingId),
      options: Options(validateStatus: (status) => true),
    );

    final status = res.statusCode ?? 0;
    final raw = res.data;

    if (status < 200 || status >= 300) {
      throw Exception('completeUpload failed: status=$status body=$raw');
    }

    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return RecordingDto.fromJson(raw['data']);
      }
      try {
        return RecordingDto.fromJson(raw);
      } catch (_) {
        throw Exception('completeUpload: unexpected data shape');
      }
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
            return RecordingDto.fromJson(decoded['data']);
          }
          return RecordingDto.fromJson(decoded);
        }
      } catch (_) {
        throw Exception('completeUpload: failed to decode response');
      }
    }
    throw Exception('completeUpload: unexpected response type ${raw.runtimeType}');
  }
  Future<List<RecordingDto>> getRecordings({Map<String, dynamic>? query}) async {
    final res = await dioClient.get(RecordingEndpoints.recordings, queryParameters: query);
    final data = res.data;
    if (data is! List) {
      throw StateError('Expected List from GET ${RecordingEndpoints.recordings}');
    }
    return data.map((e) => RecordingDto.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<RecordingDto> getRecording(String recordingId) async {
    final res = await dioClient.get(RecordingEndpoints.recording(recordingId));
    return RecordingDto.fromJson(res.data as Map<String, dynamic>);
  }
  Future<void> deleteRecording(String recordingId) async {
    await dioClient.delete(RecordingEndpoints.deleteRecording(recordingId));
  }
  Future<void> rename(String recordingId, String name) async {
    await dioClient.put(RecordingEndpoints.rename(recordingId), data: {'name': name});
  }
  Future<void> duplicate(String recordingId) async {
    await dioClient.post(RecordingEndpoints.duplicate(recordingId));
  }
}
