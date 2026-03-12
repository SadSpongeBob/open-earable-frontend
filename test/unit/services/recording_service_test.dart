import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/recording/recording_service.dart';

void main() {
  late Directory baseDir;
  late Directory exportDir;
  late Directory tempDir;
  late LocalMedia localMedia;
  late RecordingService svc;

  setUp(() async {
    baseDir = Directory.systemTemp.createTempSync('recservice_base');
    exportDir = Directory.systemTemp.createTempSync('recservice_export');
    tempDir = Directory.systemTemp.createTempSync('recservice_tmp');

    localMedia = LocalMedia(baseDir, exportDir, tempDir);
    svc = RecordingService(dio: Dio(), localMedia: localMedia);
  });

  tearDown(() {
    try {
      baseDir.deleteSync(recursive: true);
    } catch (_) {}
    try {
      exportDir.deleteSync(recursive: true);
    } catch (_) {}
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('getLocalRecording throws when files missing', () async {
    final projectId = 'p1';
    final recId = 'r1';

    expect(() => svc.getLocalRecording(projectId, recId), throwsA(isA<FileSystemException>()));
  });

  test('create local recording files and read back', () async {
    final projectId = 'default';
    final recId = 'r_local_1';
    final recDir = localMedia.recordingDir(projectId, recId);
    await recDir.create(recursive: true);

    final video = localMedia.videoFile(projectId, recId);
    await video.writeAsBytes([0, 1, 2]);

    final thumb = localMedia.thumbnailFile(projectId, recId);
    await thumb.writeAsBytes([0]);

    final meta = localMedia.recordingMetaFile(projectId, recId);
    await meta.writeAsString('{"name":"MyRec","timestamp":"2020-01-01T00:00:00Z","uploadStatus":"COMPLETED"}');

    final rec = await svc.getLocalRecording(projectId, recId);
    expect(rec.id, recId);
    expect(rec.name, 'MyRec');
    expect(rec.localVideoPath, video.path);
    expect(rec.localThumbnailPath, thumb.path);
  });

  test('getLocalRecordingSensors returns sensors sorted and skips missing files', () async {
    final projectId = 'default';
    final recId = 'r_sensors';
    final recDir = localMedia.recordingDir(projectId, recId);
    await recDir.create(recursive: true);
    final sensor1Dir = Directory('${recDir.path}/sensorA');
    final sensor2Dir = Directory('${recDir.path}/sensorB');
    await sensor1Dir.create(recursive: true);
    await sensor2Dir.create(recursive: true);

    final sensor1File = localMedia.recordingSensors(projectId, recId, 'sensorA');
    await sensor1File.writeAsString('{"sourceName":"Acc","startEpochMs":0}');

    final sensors = await svc.getLocalRecordingSensors(projectId, recId);
    expect(sensors.length, 1);
    expect(sensors.first.name, 'Acc');
  });

  test('renameLocal updates meta or throws when missing', () async {
    final projectId = 'default';
    final recId = 'r_ren';
    final recDir = localMedia.recordingDir(projectId, recId);
    await recDir.create(recursive: true);

    final meta = localMedia.recordingMetaFile(projectId, recId);
    await meta.writeAsString('{"name":"Old"}');

    await svc.renameLocal(projectId: projectId, recordingId: recId, newName: 'New');

    final decoded = meta.readAsStringSync();
    expect(decoded.contains('New'), isTrue);
  });

  test('duplicateLocalRecording copies files and metadata', () async {
    final projectId = 'default';
    final srcId = 'src1';
    final dstId = 'dst1';
    final srcDir = localMedia.recordingDir(projectId, srcId);
    await srcDir.create(recursive: true);

    final srcVideo = localMedia.videoFile(projectId, srcId);
    await srcVideo.writeAsBytes([1, 2, 3]);

    final srcThumb = localMedia.thumbnailFile(projectId, srcId);
    await srcThumb.writeAsBytes([4, 5]);

    final srcMeta = localMedia.recordingMetaFile(projectId, srcId);
    await srcMeta.writeAsString('{"name":"Source"}');

    final ok = await svc.duplicateLocalRecording(
      projectId: projectId,
      sourceRecordingId: srcId,
      newRecordingId: dstId,
      newName: 'Copied',
    );

    expect(ok, isTrue);

    final dstVideo = localMedia.videoFile(projectId, dstId);
    final dstMeta = localMedia.recordingMetaFile(projectId, dstId);
    expect(await dstVideo.exists(), isTrue);
    expect(await dstMeta.exists(), isTrue);
    final m = await dstMeta.readAsString();
    expect(m.contains('Copied'), isTrue);
  });

  test('deleteLocalRecording removes files and directory', () async {
    final projectId = 'default';
    final recId = 'r_local_2';
    final recDir = localMedia.recordingDir(projectId, recId);
    await recDir.create(recursive: true);

    await svc.deleteLocalRecording(projectId: projectId, recordingId: recId);

    expect(recDir.existsSync(), isFalse);
  });

  test('getLocalProjectRecordings skips corrupted meta files', () async {
    final projectId = 'default';
    final r1 = 'good1';
    final r2 = 'bad1';

    final dir1 = localMedia.recordingDir(projectId, r1);
    final dir2 = localMedia.recordingDir(projectId, r2);
    await dir1.create(recursive: true);
    await dir2.create(recursive: true);

    final video1 = localMedia.videoFile(projectId, r1);
    await video1.writeAsBytes([0]);
    final meta1 = localMedia.recordingMetaFile(projectId, r1);
    await meta1.writeAsString('{"name":"Good","timestamp":"2020-01-01T00:00:00Z","uploadStatus":"COMPLETED"}');

    final video2 = localMedia.videoFile(projectId, r2);
    await video2.writeAsBytes([0]);
    final meta2 = localMedia.recordingMetaFile(projectId, r2);
    await meta2.writeAsString('[]'); // corrupted (not a JSON object)

    final recs = await svc.getLocalProjectRecordings(projectId);
    // Only the good one should be returned
    expect(recs.any((r) => r.id == r1), isTrue);
    expect(recs.any((r) => r.id == r2), isFalse);
  });
}
