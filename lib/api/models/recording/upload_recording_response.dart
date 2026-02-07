class UploadRecordingResponse {
  final String recordingId;
  final String name;
  final String? projectId;
  final UploadInfo videoUpload;
  final List<SensorUploadInfo> sensorUploads;
  final UploadInfo? thumbnailUpload;

  UploadRecordingResponse({
    required this.recordingId,
    required this.name,
    this.projectId,
    required this.videoUpload,
    required this.sensorUploads,
    this.thumbnailUpload,
  });

  factory UploadRecordingResponse.fromJson(Map<String, dynamic> json) {


    final rawData = (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;

    final recordingId = rawData['recordingId'] as String;
    final name = rawData['name'] as String;
    final projectId = rawData['projectId'] as String?;

    final videoUploadRaw = rawData['videoUpload'];
    final videoUpload = UploadInfo.fromJson(Map<String, dynamic>.from(videoUploadRaw));

    final sensorUploadsRaw = rawData['sensorUploads'];
    final sensorUploads = <SensorUploadInfo>[];
    for (final e in sensorUploadsRaw) {
      sensorUploads.add(SensorUploadInfo.fromJson(Map<String, dynamic>.from(e)));
    }

    final thumbnailRaw = rawData['thumbnailUpload'];
    final thumbnailUpload = (thumbnailRaw is Map) ? UploadInfo.fromJson(Map<String, dynamic>.from(thumbnailRaw)) : null;

    return UploadRecordingResponse(
      recordingId: recordingId,
      name: name,
      projectId: projectId,
      videoUpload: videoUpload,
      sensorUploads: sensorUploads,
      thumbnailUpload: thumbnailUpload,
    );
  }
}

class UploadInfo {
  final String filename;
  final String key;
  final String uploadUrl;
  final String timestamp;
  final Map<String, String> requiredHeaders;

  UploadInfo({
    required this.filename,
    required this.key,
    required this.uploadUrl,
    required this.timestamp,
    required this.requiredHeaders,
  });

  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    final filename = json['filename'] as String? ?? '';
    final key = json['key'] as String? ?? '';
    final uploadUrl = json['uploadUrl'] as String;
    final timestamp = json['timestamp'] as String? ?? '';
    final rawHeaders = json['requiredHeaders'];
    final headers = <String, String>{};
    rawHeaders.forEach((k, v) {
      if (k is String && v != null) headers[k] = v.toString();
    });

    return UploadInfo(
      filename: filename,
      key: key,
      uploadUrl: uploadUrl,
      timestamp: timestamp,
      requiredHeaders: headers,
    );
  }
}

class SensorUploadInfo {
  final String sensorId;
  final int sensorIndex;
  final String name;
  final UploadInfo sensor;
  final String type;

  SensorUploadInfo({
    required this.sensorId,
    required this.sensorIndex,
    required this.name,
    required this.sensor,
    required this.type,
  });
  ///I will fix this when sensors are ready

  factory SensorUploadInfo.fromJson(Map<String, dynamic> json) {
    final sensorId = json['sensorId'] as String? ?? '';
    final sensorIndex = (json['sensorIndex'] is int) ? json['sensorIndex'] as int : int.tryParse('${json['sensorIndex'] ?? ''}') ?? 0;
    final name = json['name'] as String? ?? '';
    final sensorRaw = json['sensor'] as Map<String, dynamic>?;
    if (sensorRaw == null) throw Exception('sensor field missing in SensorUploadInfo');
    final sensor = UploadInfo.fromJson(sensorRaw);
    final type = json['type'] as String? ?? '';
    return SensorUploadInfo(
      sensorId: sensorId,
      sensorIndex: sensorIndex,
      name: name,
      sensor: sensor,
      type: type,
    );
  }
}