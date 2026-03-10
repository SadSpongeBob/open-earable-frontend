import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:openearable/features/playback/controllers/sensor_chart_controller.dart';
import 'package:openearable/features/playback/controllers/chart_data.dart';
import 'package:openearable/features/playback/widgets/sensor_chart_player.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
class MockLocalMedia extends Mock implements LocalMedia {}
class MockRecordingService extends Mock implements RecordingService {}
class MockS3Service extends Mock implements S3Service {}
class MockUploadController extends Mock implements UploadController {}
class MockProjectService extends Mock implements ProjectService {}
class MockVideoController extends Mock implements VideoPlayerController {}
MockVideoController makeMockVideoController({
  bool initialized = false,
  bool isPlaying = false,
  Duration duration = const Duration(seconds: 60),
  Duration position = Duration.zero,
}) {
  final vc = MockVideoController();
  final value = VideoPlayerValue(
    duration: duration,
    position: position,
    isInitialized: initialized,
    isPlaying: isPlaying,
  );

  when(() => vc.value).thenReturn(value);
  when(() => vc.pause()).thenAnswer((_) async {});
  when(() => vc.play()).thenAnswer((_) async {});
  when(() => vc.seekTo(any())).thenAnswer((_) async {});
  return vc;
}

class TestSessionNotifier extends SessionNotifier {
  TestSessionNotifier(AuthState initial) : super() {
    state = initial;
  }
}

DioException dioEx(int status) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(requestOptions: RequestOptions(path: '/'), statusCode: status),
);

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('PlaybackController - unit', () {
    late MockLocalMedia localMedia;
    late MockRecordingService recordingService;
    late MockS3Service s3Service;
    late MockUploadController uploadController;
    late MockProjectService projectService;

    ProviderContainer buildContainer({required AuthState authState}) {
      localMedia = MockLocalMedia();
      recordingService = MockRecordingService();
      s3Service = MockS3Service();
      uploadController = MockUploadController();
      projectService = MockProjectService();

      final container = ProviderContainer(overrides: [
        localMediaProvider.overrideWithValue(localMedia),
        recordingServiceProvider.overrideWithValue(recordingService),
        s3ServiceProvider.overrideWithValue(s3Service),
        projectServiceProvider.overrideWithValue(projectService),
        sessionProvider.overrideWith((ref) => TestSessionNotifier(authState)),
        uploadControllerProvider.overrideWithValue(uploadController),
        homeStateProvider.overrideWith((ref) => HomeStateNotifier()),
      ]);

      addTearDown(container.dispose);
      return container;
    }

    test('provider returns a controller instance', () {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);
      expect(controller, isNotNull);
    });

    test('seekBySeconds handles invalid controller gracefully', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final vc = makeMockVideoController(initialized: true);
      expect(() => controller.seekBySeconds(vc, 10), returnsNormally);
    });

    test('togglePlay returns normally for invalid controller', () {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final vc = makeMockVideoController(initialized: true, isPlaying: false);
      expect(() => controller.togglePlay(vc), returnsNormally);
    });

    test('getAvailableSensors returns local sensors when recording is local', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording.local(
        id: 'r1',
        name: 'name',
        localVideoPath: '/tmp/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        projectId: 'p1',
      );

      when(() => recordingService.getLocalRecordingSensors('p1', 'r1'))
          .thenAnswer((_) async => [
                Sensor(sensorIndex: 0, sensorId: 's1', name: 'Accel', timeStamp: DateTime.now(), localPath: '/tmp/s1')
              ]);

      final sensors = await controller.getAvailableSensors(rec);

      expect(sensors, isNotEmpty);
      expect(sensors.first.sensorId, 's1');
    });

    test('getAvailableSensors downloads cloud sensors and returns them', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rcloud',
        name: 'cloud',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
        projectId: 'p',
      );

      final sensorEntry = GetSensorResponse(
        sensorId: 's1',
        sensorIndex: 0,
        name: 'Accelerometer',
        url: 'https://example.com/s1.json',
        type: SensorType.accelerometer,
        timestamp: DateTime.now().toUtc(),
      );

      final getRec = GetRecordingResponse(
        recordingId: 'rcloud',
        name: 'cloud',
        videoUrl: 'https://example.com/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        sensors: [sensorEntry],
        projectId: 'p',
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      when(() => recordingService.getRecording('rcloud')).thenAnswer((_) async => getRec);

      when(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath')))
          .thenAnswer((inv) async {
        final path = inv.namedArguments[#filePath] as String;
        final f = File(path);
        await f.create(recursive: true);
        await f.writeAsString('[]');
        return;
      });

      when(() => localMedia.recordingTempSensors(any())).thenReturn(File('${Directory.systemTemp.path}/tmp_sensor.json'));

      final sensors = await controller.getAvailableSensors(rec);
      expect(sensors, isNotEmpty);
      expect(sensors.first.sensorId, isNotNull);

      verify(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath'))).called(getRec.sensors.length);
    });

    test('renameRecording updates home state and keeps id stable', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));final controller = container.read(playbackControllerProvider);

      final rec = Recording.local(
        id: 'r1',
        name: 'old',
        localVideoPath: '/tmp/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        projectId: 'p',
      );

      when(() => recordingService.renameLocal(projectId: any(named: 'projectId'), recordingId: any(named: 'recordingId'), newName: any(named: 'newName')))
          .thenAnswer((_) async => Future.value());

      final homeNotifier = container.read(homeStateProvider.notifier);
      homeNotifier.addRecording(rec);

      await controller.renameRecording(rec, 'new');

      final state = container.read(homeStateProvider);
      expect(state.recordings.where((r) => r.id == 'r1').first.name, 'new');
    });

    test('deleteRecording removes recording from home state', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording.local(
        id: 'rdel',
        name: 'toDel',
        localVideoPath: '/tmp/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        projectId: 'p',
      );

      final home = container.read(homeStateProvider.notifier);
      home.addRecording(rec);
      expect(container.read(homeStateProvider).recordings.any((r) => r.id == 'rdel'), isTrue);

      when(() => recordingService.deleteLocalRecording(projectId: any(named: 'projectId'), recordingId: any(named: 'recordingId')))
          .thenAnswer((_) async => true);

      await controller.deleteRecording(rec);

      expect(container.read(homeStateProvider).recordings.any((r) => r.id == 'rdel'), isFalse);
    });

    test('cloud sensor download flow handles empty/successful files', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rcloud2',
        name: 'cloud2',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final sensorEntry = GetSensorResponse(
        sensorId: 's1',
        sensorIndex: 0,
        name: 'Accelerometer',
        url: 'https://example.com/s1.json',
        type: SensorType.accelerometer,
        timestamp: DateTime.now().toUtc(),
      );

      final getRec = GetRecordingResponse(
        recordingId: 'rcloud2',
        name: 'cloud2',
        videoUrl: 'https://example.com/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        sensors: [sensorEntry],
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      when(() => recordingService.getRecording('rcloud2')).thenAnswer((_) async => getRec);

      when(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath')))
          .thenAnswer((inv) async {
        final path = inv.namedArguments[#filePath] as String;
        final f = File(path);
        await f.create(recursive: true);
        await f.writeAsString('[{"timestampMs": ${DateTime.now().toUtc().millisecondsSinceEpoch}, "values": {"Accelerometer": [0.1,0.2,0.3]}}]');
      });

      when(() => localMedia.recordingTempSensors(any())).thenReturn(File('${Directory.systemTemp.path}/tmp_sensor2.json'));

      final sensors = await controller.getAvailableSensors(rec);

      expect(sensors, isNotEmpty);
      verify(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath'))).called(1);
    });

    test('seekBySeconds clamps to start and end', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final vcStart = makeMockVideoController(initialized: true, duration: const Duration(seconds: 60), position: const Duration(seconds: 5));
      controller.seekBySeconds(vcStart, -10);
      verify(() => vcStart.seekTo(Duration.zero)).called(1);

      final vcEnd = makeMockVideoController(initialized: true, duration: const Duration(seconds: 60), position: const Duration(seconds: 58));
      controller.seekBySeconds(vcEnd, 10);
      verify(() => vcEnd.seekTo(const Duration(seconds: 60))).called(1);
    });

    test('togglePlay pauses when playing and plays when paused', () {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final playing = makeMockVideoController(initialized: true, isPlaying: true);
      controller.togglePlay(playing);
      verify(() => playing.pause()).called(1);

      final paused = makeMockVideoController(initialized: true, isPlaying: false);
      controller.togglePlay(paused);
      verify(() => paused.play()).called(1);
    });

    test('deleteRecording cloud calls deleteCloudRecording and removes from home', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rc_del_cloud',
        name: 'cloud-del',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final home = container.read(homeStateProvider.notifier);
      home.addRecording(rec);
      expect(container.read(homeStateProvider).recordings.any((r) => r.id == 'rc_del_cloud'), isTrue);

      when(() => recordingService.deleteCloudRecording('rc_del_cloud')).thenAnswer((_) async => Future.value());

      await controller.deleteRecording(rec);

      expect(container.read(homeStateProvider).recordings.any((r) => r.id == 'rc_del_cloud'), isFalse);
      verify(() => recordingService.deleteCloudRecording('rc_del_cloud')).called(1);
    });

    test('renameRecording cloud updates home state', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rc_rename_cloud',
        name: 'oldName',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final home = container.read(homeStateProvider.notifier);
      home.addRecording(rec);

      when(() => recordingService.renameCloud(recordingId: 'rc_rename_cloud', name: 'newName')).thenAnswer((_) async => Future.value());

      await controller.renameRecording(rec, 'newName');

      expect(container.read(homeStateProvider).recordings.where((r) => r.id == 'rc_rename_cloud').first.name, 'newName');
      verify(() => recordingService.renameCloud(recordingId: 'rc_rename_cloud', name: 'newName')).called(1);
    });

    test('exportVideoFolder cloud downloads video and sensors to export dir', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rcloud_exp',
        name: 'export-me',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final sensorEntry = GetSensorResponse(
        sensorId: 's_export',
        sensorIndex: 0,
        name: 'SensorExport',
        url: 'https://example.com/s_exp.json',
        type: SensorType.accelerometer,
        timestamp: DateTime.now().toUtc(),
      );

      final getRec = GetRecordingResponse(
        recordingId: 'rcloud_exp',
        name: 'export-me',
        videoUrl: 'https://example.com/video.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        sensors: [sensorEntry],
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      when(() => recordingService.getRecording('rcloud_exp')).thenAnswer((_) async => getRec);

      final tmp = await Directory.systemTemp.createTemp('exp_test');
      when(() => localMedia.recordingExportDir('export-me')).thenReturn(tmp);
      when(() => localMedia.videoExportFile('rcloud_exp')).thenReturn(File('${tmp.path}/video.mp4'));
      when(() => localMedia.sensorExportFile('rcloud_exp', 'SensorExport')).thenReturn(File('${tmp.path}/SensorExport.json'));

      when(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath'))).thenAnswer((inv) async {
        final path = inv.namedArguments[#filePath] as String;
        final f = File(path);
        await f.create(recursive: true);
        await f.writeAsString('ok');
      });

      await controller.exportVideoFolder(rec);

      expect(File('${tmp.path}/video.mp4').existsSync(), isTrue);
      expect(File('${tmp.path}/SensorExport.json').existsSync(), isTrue);

      await tmp.delete(recursive: true);
    });

    test('getAvailableSensors skips sensors that fail to download', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rcloud_fail',
        name: 'cloudfail',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final sensorEntry = GetSensorResponse(
        sensorId: 'sfail',
        sensorIndex: 0,
        name: 'FailSensor',
        url: 'https://example.com/fail.json',
        type: SensorType.accelerometer,
        timestamp: DateTime.now().toUtc(),
      );

      final getRec = GetRecordingResponse(
        recordingId: 'rcloud_fail',
        name: 'cloudfail',
        videoUrl: 'https://example.com/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        sensors: [sensorEntry],
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      when(() => recordingService.getRecording('rcloud_fail')).thenAnswer((_) async => getRec);

      when(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath'))).thenThrow(Exception('download failed'));

      when(() => localMedia.recordingTempSensors(any())).thenReturn(File('${Directory.systemTemp.path}/tmp_fail.json'));

      final sensors = await controller.getAvailableSensors(rec);

      expect(sensors, isEmpty);
    });

    test('renameRecording denied if projectService returns 403', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.authenticated, user: null));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'r403',
        name: 'r403',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
        projectId: 'proj403',
      );

      when(() => projectService.getProjectUsers('proj403')).thenThrow(dioEx(403));

      await controller.renameRecording(rec, 'new');
      verifyNever(() => recordingService.renameCloud(recordingId: any(named: 'recordingId'), name: any(named: 'name')));
    });

    test('exportVideoFolder local copies non-meta files', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final tmpBase = await Directory.systemTemp.createTemp('lm_base');
      final projectId = 'p_local_exp';
      final recId = 'r_local_exp';
      final projectDir = Directory('${tmpBase.path}/$projectId');
      final recDir = Directory('${projectDir.path}/$recId');
      await recDir.create(recursive: true);

      final videoFile = File('${recDir.path}/${LocalMedia.videoName}');
      await videoFile.writeAsString('video');
      final metaFile = File('${recDir.path}/${LocalMedia.metaName}');
      await metaFile.writeAsString('{}');
      final otherFile = File('${recDir.path}/extra.txt');
      await otherFile.writeAsString('x');

      when(() => localMedia.projectDir(projectId)).thenReturn(projectDir);
      when(() => localMedia.recordingDir(projectId, recId)).thenReturn(recDir);

      final rec = Recording.local(
        id: recId,
        name: 'local-export',
        localVideoPath: videoFile.path,
        videoTimestamp: DateTime.now().toUtc(),
        projectId: projectId,
      );

      final tmpExport = await Directory.systemTemp.createTemp('exp_out');
      when(() => localMedia.recordingExportDir(any())).thenReturn(tmpExport);

      await controller.exportVideoFolder(rec);

      final exportedVideo = File('${tmpExport.path}/${LocalMedia.videoName}');
      final exportedExtra = File('${tmpExport.path}/extra.txt');
      expect(exportedVideo.existsSync(), isTrue);
      expect(exportedExtra.existsSync(), isTrue);

      await tmpBase.delete(recursive: true);
      await tmpExport.delete(recursive: true);
    });

    test('exportVideoFolder cloud propagates download exceptions', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording(
        id: 'rcloud_err',
        name: 'export-err',
        source: RecordingSource.cloud,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );

      final sensorEntry = GetSensorResponse(
        sensorId: 's_e',
        sensorIndex: 0,
        name: 'SERR',
        url: 'https://example.com/serr.json',
        type: SensorType.accelerometer,
        timestamp: DateTime.now().toUtc(),
      );

      final getRec = GetRecordingResponse(
        recordingId: 'rcloud_err',
        name: 'export-err',
        videoUrl: 'https://example.com/video.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        sensors: [sensorEntry],
        projectId: null,
        userId: 'u',
        uploadStatus: UploadStatus.pending,
      );

      when(() => recordingService.getRecording('rcloud_err')).thenAnswer((_) async => getRec);

      when(() => s3Service.downloadToFile(getUrl: any(named: 'getUrl'), filePath: any(named: 'filePath'))).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

      final tmp = await Directory.systemTemp.createTemp('exp_err');
      when(() => localMedia.recordingExportDir(any())).thenReturn(tmp);
      when(() => localMedia.videoExportFile('rcloud_err')).thenReturn(File('${tmp.path}/video.mp4'));
      when(() => localMedia.sensorExportFile('rcloud_err', any())).thenReturn(File('${tmp.path}/s.json'));

      expect(() => controller.exportVideoFolder(rec), throwsA(isA<DioException>()));

      await tmp.delete(recursive: true);
    });

    test('renameRecording for default project calls local rename', () async {
      final container = buildContainer(authState: const AuthState(mode: AuthMode.guest));
      final controller = container.read(playbackControllerProvider);

      final rec = Recording.local(
        id: 'rdef',
        name: 'def',
        localVideoPath: '/tmp/v.mp4',
        videoTimestamp: DateTime.now().toUtc(),
        projectId: LocalMedia.defaultProjectId,
      );

      when(() => recordingService.renameLocal(projectId: LocalMedia.defaultProjectId, recordingId: 'rdef', newName: 'nn'))
          .thenAnswer((_) async => Future.value());

      final home = container.read(homeStateProvider.notifier);
      home.addRecording(rec);

      await controller.renameRecording(rec, 'nn');

      verify(() => recordingService.renameLocal(projectId: LocalMedia.defaultProjectId, recordingId: 'rdef', newName: 'nn')).called(1);
    });
  });

  group('SensorChartController - unit', () {
    test('SensorChartController.windowFor returns correct samples', () {
      final samples = List.generate(5, (i) => SensorSample(timestampMs: i * 30, x: i.toDouble(), y: i.toDouble(), z: i.toDouble()));
      final ctrl = SensorChartController(samples: samples, windowMs: 100);

      final window = ctrl.windowFor(150);
      final timestamps = window.map((s) => s.timestampMs).toList();
      expect(timestamps, [60, 90, 120]);
    });

    test('ChartData.fromSamples interpolates values at stepMs', () {
      final samples = [
        SensorSample(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0),
        SensorSample(timestampMs: 100, x: 100.0, y: 100.0, z: 100.0),
      ];

      final cd = ChartData.fromSamples(samples, 0, 100, stepMs: 50);
      expect(cd.resTs, [0, 50, 100]);
      expect(cd.rx.length, 3);
      expect(cd.rx[0], closeTo(0.0, 1e-6));
      expect(cd.rx[1], closeTo(50.0, 1e-6));
      expect(cd.rx[2], closeTo(100.0, 1e-6));
    });

    test('Integration: window + ChartData produces monotonic timestamps and bounded values', () {
      final samples = List.generate(11, (i) {
        final t = i * 30;
        final v = t / 100.0;
        return SensorSample(timestampMs: t, x: v, y: v, z: v);
      });

      final ctrl = SensorChartController(samples: samples, windowMs: 120);
      final currentMs = 210;
      final windowSamples = ctrl.windowFor(currentMs);
      expect(windowSamples.every((s) => s.timestampMs >= 90 && s.timestampMs <= 210), isTrue);

      final cd = ChartData.fromSamples(windowSamples, 90, 210, stepMs: 30);
      expect(cd.resTs, [90, 120, 150, 180, 210]);
      expect(cd.rx.length, cd.resTs.length);
      final minOriginal = windowSamples.map((s) => s.x).reduce((a, b) => a < b ? a : b);
      final maxOriginal = windowSamples.map((s) => s.x).reduce((a, b) => a > b ? a : b);
      expect(cd.minV, lessThan(maxOriginal + 1e-6));
      expect(cd.maxV, greaterThan(minOriginal - 1e-6));
    });
  });

  testWidgets('SensorChartPlayer updates _currentMs when controller position changes', (tester) async {
    final samples = List.generate(11, (i) => SensorSample(timestampMs: i * 30, x: i.toDouble(), y: i.toDouble(), z: i.toDouble()));

    final vc = MockVideoController();
    VideoPlayerValue currentValue = VideoPlayerValue(
      duration: const Duration(seconds: 60),
      position: Duration.zero,
      isInitialized: true,
      isPlaying: false,
    );

    final listeners = <VoidCallback>[];
    when(() => vc.addListener(any())).thenAnswer((inv) {
      final cb = inv.positionalArguments[0] as VoidCallback;
      listeners.add(cb);
    });
    when(() => vc.removeListener(any())).thenAnswer((inv) {
      final cb = inv.positionalArguments[0] as VoidCallback;
      listeners.remove(cb);
    });
    when(() => vc.value).thenAnswer((_) => currentValue);

    await tester.pumpWidget(MaterialApp(home: SensorChartPlayer(controller: vc, samples: samples)));
    await tester.pumpAndSettle();

    final cpFinder = find.descendant(of: find.byType(SensorChartPlayer), matching: find.byType(CustomPaint));
    expect(cpFinder, findsOneWidget);
    final cp = tester.widget<CustomPaint>(cpFinder);
    final painterInitial = cp.painter as dynamic;
    expect(painterInitial.endMs, 0);

    currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: const Duration(milliseconds: 150), isInitialized: true, isPlaying: true);
    for (final l in listeners) l();
    await tester.pumpAndSettle();

    final cp2 = tester.widget<CustomPaint>(cpFinder);
    final painter = cp2.painter as dynamic;
    expect(painter.endMs, 150);
    final windowSamples = painter.data;
    expect(painter.startMs <= painter.endMs, isTrue);
  });

  testWidgets('SensorChartPlayer removes listener on dispose', (tester) async {
    final samples = List.generate(5, (i) => SensorSample(timestampMs: i * 30, x: i.toDouble(), y: i.toDouble(), z: i.toDouble()));
    final vc = MockVideoController();
    VideoPlayerValue currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: Duration.zero, isInitialized: true, isPlaying: false);
    final listeners = <VoidCallback>[];
    when(() => vc.addListener(any())).thenAnswer((inv) { listeners.add(inv.positionalArguments[0] as VoidCallback); });
    when(() => vc.removeListener(any())).thenAnswer((inv) { listeners.remove(inv.positionalArguments[0] as VoidCallback); });
    when(() => vc.value).thenAnswer((_) => currentValue);

    await tester.pumpWidget(MaterialApp(home: SensorChartPlayer(controller: vc, samples: samples)));
    await tester.pumpAndSettle();

    expect(listeners.isNotEmpty, isTrue);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();

    expect(listeners.isEmpty, isTrue);
  });

  testWidgets('SensorChartPlayer reflects final position after rapid updates', (tester) async {
    final samples = List.generate(20, (i) => SensorSample(timestampMs: i * 30, x: i.toDouble(), y: i.toDouble(), z: i.toDouble()));
    final vc = MockVideoController();
    VideoPlayerValue currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: Duration.zero, isInitialized: true, isPlaying: false);
    final listeners = <VoidCallback>[];
    when(() => vc.addListener(any())).thenAnswer((inv) { listeners.add(inv.positionalArguments[0] as VoidCallback); });
    when(() => vc.removeListener(any())).thenAnswer((inv) { listeners.remove(inv.positionalArguments[0] as VoidCallback); });
    when(() => vc.value).thenAnswer((_) => currentValue);

    await tester.pumpWidget(MaterialApp(home: SensorChartPlayer(controller: vc, samples: samples)));
    await tester.pumpAndSettle();

    final cpFinder = find.descendant(of: find.byType(SensorChartPlayer), matching: find.byType(CustomPaint));
    expect(cpFinder, findsOneWidget);

    currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: const Duration(milliseconds: 100), isInitialized: true, isPlaying: true);
    for (final l in List<VoidCallback>.from(listeners)) l();
    await tester.pump();

    currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: const Duration(milliseconds: 200), isInitialized: true, isPlaying: true);
    for (final l in List<VoidCallback>.from(listeners)) l();
    await tester.pump();

    currentValue = VideoPlayerValue(duration: const Duration(seconds: 60), position: const Duration(milliseconds: 300), isInitialized: true, isPlaying: true);
    for (final l in List<VoidCallback>.from(listeners)) l();
    await tester.pumpAndSettle();

    final cpFinal = tester.widget<CustomPaint>(cpFinder);
    final painterFinal = cpFinal.painter as dynamic;
    expect(painterFinal.endMs, 300);
  });
}
