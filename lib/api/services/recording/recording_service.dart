import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../models/recording/upload_recording_request.dart';
import '../../models/recording/upload_recording_response.dart';
import '../../models/recording/recording_dto.dart';
import '../auth/token_storage.dart';
import 'recording_endpoints.dart';

/// Service für Recording-bezogene API-Aufrufe.
/// Methoden:
/// - startUpload: POST /api/recording
/// - completeUpload: PUT /api/recording/{id}/complete
/// - getRecordings: GET /api/recording (mit Query)
/// - getRecording: GET /api/recording/{id}
/// - delete/rename/duplicate
class RecordingService {
  final Dio dioClient;

  RecordingService({required this.dioClient});

  // Getter to expose the underlying Dio instance so callers can reuse it
  // (important when upload URLs are relative and dio has a baseUrl configured).
  Dio get dio => dioClient;

  /// Startet den Upload-Prozess; Backend gibt Upload-URLs zurück.
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) async {
    final res = await dioClient.post<dynamic>(
      RecordingEndpoints.startUpload,
      data: req.toJson(),
      options: Options(
        // don't throw automatically on non-2xx so we can inspect body
        validateStatus: (status) => true,
      ),
    );

    final raw = res.data;

    // If server returned an error status, include body in exception to help
    if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
      throw Exception('startUpload failed: status=${res.statusCode} body=${raw}');
    }

    // Handle typical shapes:
    // 1) { "data": { ... } }  -> pass through
    // 2) { ... } (inner object returned directly) -> wrap into {"data": raw}
    // 3) null or unexpected -> throw with helpful message
    if (raw == null) {
      throw Exception('startUpload: response.data is null (status=${res.statusCode})');
    }

    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return UploadRecordingResponse.fromJson(raw);
      }

      // backend returned the inner object directly, wrap it
      return UploadRecordingResponse.fromJson({'data': raw});
    }

    // If it's a string, try to decode JSON (best-effort)
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
            return UploadRecordingResponse.fromJson(decoded);
          }
          return UploadRecordingResponse.fromJson({'data': decoded});
        }
      } catch (_) {
        // fall through to error below
      }
    }

    throw Exception('startUpload: unexpected response shape: ${raw.runtimeType} (status=${res.statusCode})');
  }
  Future<RecordingDto?> completeUpload(String recordingId, {Dio? dioClient}) async {
    final dio = dioClient ?? Dio();
    final tokenStorage = TokenStorage();
    final accessToken = await tokenStorage.readAccessToken();
    final res = await dio.put(
      'http://167.71.50.147:8080/api/recording/$recordingId/complete',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
    return RecordingDto.fromJson(res.data['data']);
  }


  /// Holt eine Liste von Recordings mit optionalen Query-Parametern.
  Future<List<RecordingDto>> getRecordings({Map<String, dynamic>? query}) async {
    final res = await dioClient.get<dynamic>(
      RecordingEndpoints.recordings,
      queryParameters: query,
    );

    final data = res.data;
    if (data is! List) {
      throw StateError('Expected List from GET ${RecordingEndpoints.recordings}');
    }

    return data
        .map((e) => RecordingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecordingDto> getRecording(String recordingId) async {
    final res = await dioClient.get<dynamic>(
      RecordingEndpoints.recording(recordingId),
    );

    final data = res.data as Map<String, dynamic>;
    return RecordingDto.fromJson(data);
  }

  /// Löscht eine Aufnahme.
  Future<void> deleteRecording(String recordingId) async {
    await dioClient.delete<dynamic>(RecordingEndpoints.deleteRecording(recordingId));
  }

  /// Umbenennen einer Aufnahme.
  Future<void> rename(String recordingId, String name) async {
    await dioClient.put<dynamic>(
      RecordingEndpoints.rename(recordingId),
      data: {'name': name},
    );
  }

  /// Duplizieren einer Aufnahme.
  Future<void> duplicate(String recordingId) async {
    await dioClient.post<dynamic>(RecordingEndpoints.duplicate(recordingId));
  }
}
