import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/api/models/recording/recording.dart';

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
}
