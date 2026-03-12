import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/api/models/recording/sensor.dart' as model_sensor;
import 'package:openearable/api/models/recording/get_recording_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UploadStatus', () {
    test('fromString parses known values', () {
      expect(UploadStatus.fromString('COMPLETED'), UploadStatus.completed);
      expect(UploadStatus.fromString('PENDING'), UploadStatus.pending);
      expect(UploadStatus.fromString('UPLOADING'), UploadStatus.uploading);
      expect(UploadStatus.fromString('FAILED'), UploadStatus.failed);
    });

    test('fromString throws on unknown', () {
      expect(() => UploadStatus.fromString('unknown'), throwsA(isA<ArgumentError>()));
    });

    test('json getter returns uppercase', () {
      expect(UploadStatus.completed.json, 'COMPLETED');
      expect(UploadStatus.pending.json, 'PENDING');
      expect(UploadStatus.uploading.json, 'UPLOADING');
      expect(UploadStatus.failed.json, 'FAILED');
    });
  });

  group('Recording model', () {
    test('local factory sets fields and defaults', () {
      final rec = Recording.local(
        id: 'r1',
        name: 'n',
        localVideoPath: '/tmp/v.mp4',
        videoTimestamp: DateTime.utc(2020),
      );

      expect(rec.id, 'r1');
      expect(rec.name, 'n');
      expect(rec.localVideoPath, '/tmp/v.mp4');
      expect(rec.isLocal, isTrue);
      expect(rec.isCloud, isFalse);
      expect(rec.uploadStatus, UploadStatus.pending);
      expect(rec.isUploaded, isFalse);
    });

    test('fromJson and boolean helpers', () {
      final map = {
        'recordingId': 'rid',
        'name': 'nm',
        'thumbnailUrl': 'https://example.com/t.jpg',
        'videoTimestamp': '2021-01-02T03:04:05Z',
        'projectId': 'p',
        'userId': 'u',
        'uploadStatus': 'COMPLETED',
      };

      final rec = Recording.fromJson(map);
      expect(rec.id, 'rid');
      expect(rec.name, 'nm');
      expect(rec.thumbnailUrl, 'https://example.com/t.jpg');
      expect(rec.videoTimestamp.toUtc(), DateTime.parse('2021-01-02T03:04:05Z').toUtc());
      expect(rec.projectId, 'p');
      expect(rec.userId, 'u');
      expect(rec.uploadStatus, UploadStatus.completed);
      expect(rec.isCloud, isTrue);
      expect(rec.isLocal, isFalse);
      expect(rec.isUploaded, isTrue);
    });

    test('copyWith changes name and uploadStatus', () {
      final rec = Recording.local(
        id: 'r2',
        name: 'orig',
        localVideoPath: '/tmp/v2.mp4',
        videoTimestamp: DateTime.utc(2020),
        uploadStatus: UploadStatus.pending,
      );

      final copy = rec.copyWith(name: 'new', uploadStatus: UploadStatus.uploading);
      expect(copy.name, 'new');
      expect(copy.uploadStatus, UploadStatus.uploading);
      expect(copy.id, rec.id);
    });

    test('equality and hashCode compare id and source', () {
      final a = Recording.local(id: 'x', name: 'a', localVideoPath: '/x', videoTimestamp: DateTime.utc(2020));
      final b = Recording.local(id: 'x', name: 'b', localVideoPath: '/y', videoTimestamp: DateTime.utc(2020));
      final c = Recording.local(id: 'y', name: 'c', localVideoPath: '/z', videoTimestamp: DateTime.utc(2020));

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('thumbnailProvider chooses FileImage when localThumbnailPath present', () async {
      final tmp = Directory.systemTemp.createTempSync('thumb_test');
      final thumb = File('${tmp.path}/thumb.jpg');
      await thumb.writeAsBytes([1, 2, 3]);

      final rec = Recording.local(
        id: 't1',
        name: 'tt',
        localVideoPath: '/v',
        videoTimestamp: DateTime.utc(2020),
        localThumbnailPath: thumb.path,
      );

      final provider = rec.thumbnailProvider;
      expect(provider, isA<FileImage>());
      final fileImage = provider as FileImage;
      expect((fileImage.file).path, thumb.path);

      tmp.deleteSync(recursive: true);
    });

    test('thumbnailProvider chooses NetworkImage when thumbnailUrl present', () {
      final rec = Recording(
        id: 'n1',
        name: 'n',
        source: RecordingSource.cloud,
        thumbnailUrl: 'https://example.com/i.png',
        localThumbnailPath: null,
        localVideoPath: null,
        videoTimestamp: DateTime.utc(2020),
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      final provider = rec.thumbnailProvider;
      expect(provider, isA<NetworkImage>());
      final net = provider as NetworkImage;
      expect(net.url, 'https://example.com/i.png');
    });

    test('thumbnailProvider falls back to AssetImage when none provided', () {
      final rec = Recording(
        id: 'a1',
        name: 'a',
        source: RecordingSource.local,
        thumbnailUrl: null,
        localThumbnailPath: null,
        localVideoPath: '/v',
        videoTimestamp: DateTime.utc(2020),
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      final provider = rec.thumbnailProvider;
      expect(provider, isA<AssetImage>());
      final asset = provider as AssetImage;
      expect(asset.assetName, 'assets/images/video_thumbnail.png');
    });
  });

  group('Other recording models', () {
    test('Sensor equality and hashCode', () {
      final s1 = model_sensor.Sensor(sensorIndex: 0, sensorId: 's1', name: 'S1', timeStamp: DateTime.utc(2020), localPath: '/tmp/s1');
      final s2 = model_sensor.Sensor(sensorIndex: 1, sensorId: 's1', name: 'S1b', timeStamp: DateTime.utc(2021), localPath: '/tmp/s1b');
      final s3 = model_sensor.Sensor(sensorIndex: 2, sensorId: 's2', name: 'S2', timeStamp: DateTime.utc(2020), localPath: '/tmp/s2');

      expect(s1 == s2, isTrue);
      expect(s1.hashCode, s2.hashCode);
      expect(s1 == s3, isFalse);
    });

    test('ContentType and SensorType conversions', () {
      expect(ContentType.fromString('MP4'), ContentType.mp4);
      expect(ContentType.fromString('JPEG'), ContentType.jpeg);
      expect(ContentType.mp4.jsonRepresentation, 'MP4');
      expect(ContentType.jpeg.jsonRepresentation, 'JPEG');

      expect(SensorType.fromString('heart_rate'), SensorType.heartRate);
      expect(SensorType.fromString('THERMOMETER'), SensorType.thermometer);
      expect(SensorType.accelerometer.json, 'ACCELEROMETER');
      expect(() => ContentType.fromString('UNKNOWN'), throwsA(isA<ArgumentError>()));
      expect(() => SensorType.fromString('BADTYPE'), throwsA(isA<ArgumentError>()));
    });

    test('RecordingFile and SensorUpload toJson', () {
      final rf = RecordingFile(filename: 'v.mp4', contentType: ContentType.mp4, sizeBytes: 123, timestamp: DateTime.utc(2021, 1, 1));
      final rfJson = rf.toJson();
      expect(rfJson['filename'], 'v.mp4');
      expect(rfJson['contentType'], 'MP4');
      expect(rfJson['sizeBytes'], 123);
      expect(rfJson['timestamp'], DateTime.utc(2021, 1, 1).toUtc().toIso8601String());

      final su = SensorUpload(sensorIndex: 0, name: 'S1', type: SensorType.accelerometer, file: rf);
      final suJson = su.toJson();
      expect(suJson['sensorIndex'], 0);
      expect(suJson['type'], 'ACCELEROMETER');
      expect((suJson['file'] as Map)['filename'], 'v.mp4');
    });

    test('UploadRecordingRequest.toJson includes nested objects', () {
      final rf = RecordingFile(filename: 'v.mp4', contentType: ContentType.mp4, sizeBytes: 10, timestamp: DateTime.utc(2021));
      final su = SensorUpload(sensorIndex: 0, name: 'S1', type: SensorType.thermometer, file: rf);
      final req = UploadRecordingRequest(name: 'test', video: rf, sensors: [su], projectId: 'proj', thumbnailContent: ContentType.jpeg);
      final js = req.toJson();
      expect(js['name'], 'test');
      expect((js['video'] as Map)['filename'], 'v.mp4');
      expect((js['sensors'] as List).length, 1);
      expect(js['projectId'], 'proj');
      expect(js['thumbnailContent'], 'JPEG');
    });

    test('UploadRecordingResponse.fromJson and nested types', () {
      final uploadInfoJson = {
        'filename': 'v.mp4',
        'key': 'k1',
        'uploadUrl': 'https://u',
        'timestamp': '2022-01-01T00:00:00Z',
        'requiredHeaders': {'h': 'v'}
      };

      final sensorUploadJson = {
        'sensorId': 'sid',
        'sensorIndex': 0,
        'name': 'S1',
        'type': 'ACCELEROMETER',
        'sensor': uploadInfoJson,
      };

      final badSensorUploadJson = {
        'sensorId': 'sid2',
        'sensorIndex': 1,
        'name': 'S2',
        'type': 'BADTYPE',
        'sensor': uploadInfoJson,
      };

      final respJson = {
        'recordingId': 'rid',
        'name': 'n',
        'projectId': 'p',
        'videoUpload': uploadInfoJson,
        'sensorUploads': [sensorUploadJson, badSensorUploadJson],
        'thumbnailUpload': {'uploadUrl': 'turl', 'requiredHeaders': {'a': 'b'}}
      };

      final resp = UploadRecordingResponse.fromJson(respJson);
      expect(resp.recordingId, 'rid');
      expect(resp.videoUpload.filename, 'v.mp4');
      expect(resp.sensorUploads.length, 2);
      expect(resp.sensorUploads[0].type, SensorType.accelerometer);
      // bad type should fall back to heartRate
      expect(resp.sensorUploads[1].type, SensorType.heartRate);
      expect(resp.thumbnailUpload!.uploadUrl, 'turl');
    });

    test('GetRecordingResponse and GetSensorResponse fromJson', () {
      final sensorJson = {
        'sensorId': 's1',
        'sensorIndex': 0,
        'name': 'S1',
        'url': 'https://d',
        'type': 'THERMOMETER',
        'timestamp': '2022-02-02T00:00:00Z'
      };

      final json = {
        'recordingId': 'rid',
        'name': 'nm',
        'videoUrl': 'https://v',
        'videoTimestamp': '2022-03-03T00:00:00Z',
        'sensors': [sensorJson],
        'projectId': null,
        'userId': 'u',
        'uploadStatus': 'PENDING'
      };

      final got = GetRecordingResponse.fromJson(json);
      expect(got.recordingId, 'rid');
      expect(got.sensors.length, 1);
      expect(got.sensors.first.type, SensorType.thermometer);
      expect(got.uploadStatus, UploadStatus.pending);
    });
  });

}
