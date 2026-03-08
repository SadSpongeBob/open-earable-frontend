import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/api/services/user/user_preference_storage.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/home_state.dart';
import 'package:openearable/features/home/state/network_status.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';

class MockRecordingService extends Mock implements RecordingService {}

class MockS3Service extends Mock implements S3Service {}

class MockLocalMedia extends Mock implements LocalMedia {}

class MockUserPreferenceStorage extends Mock implements UserPreferenceStorage {}

class MockRecording extends Mock implements Recording {}

class MockProjectMetadata extends Mock implements ProjectMetadata {}

class MockSensor extends Mock implements Sensor {}

class MockFile extends Mock implements File {}

class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(AuthState initial) : super() {
    state = initial;
  }
}

class TestHomeStateNotifier extends HomeStateNotifier {
  TestHomeStateNotifier(HomeState initial) : super() {
    state = initial;
  }
}

class TestUploadController extends UploadController {
  TestUploadController(
    super.ref,
    super.localMedia,
    super.recordingService,
    super.s3Service,
    super.homeStateNotifier,
  );

  final List<(String recordingId, String projectId)> uploadAndForgetCalls = [];

  Recording? uploadRecordingResult;

  @override
  Future<void> uploadAndForget(String recordingId, String projectId) async {
    uploadAndForgetCalls.add((recordingId, projectId));
  }

  @override
  Future<Recording?> uploadRecording({
    required String recordingId,
    required String projectId,
    void Function(double progress)? onVideoProgress,
  }) async {
    return uploadRecordingResult;
  }
}

class SuccessUploadController extends UploadController {
  final Recording uploaded;

  SuccessUploadController(
    super.ref,
    super.localMedia,
    super.recordingService,
    super.s3Service,
    super.homeStateNotifier,
    this.uploaded,
  );

  @override
  Future<Recording?> uploadRecording({
    required String recordingId,
    required String projectId,
    void Function(double progress)? onVideoProgress,
  }) async {
    return uploaded;
  }
}

class NullUploadController extends UploadController {
  NullUploadController(
    super.ref,
    super.localMedia,
    super.recordingService,
    super.s3Service,
    super.homeStateNotifier,
  );

  @override
  Future<Recording?> uploadRecording({
    required String recordingId,
    required String projectId,
    void Function(double progress)? onVideoProgress,
  }) async {
    return null;
  }
}

DioException dioEx(int statusCode) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: statusCode,
  ),
);

File writeTempFile(Directory dir, String name, String content) {
  final file = File('${dir.path}/$name');
  file.writeAsStringSync(content);
  return file;
}

File writeTempBytesFile(Directory dir, String name, List<int> bytes) {
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync(bytes);
  return file;
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<Recording>[]);
    registerFallbackValue(<ProjectMetadata>[]);
    registerFallbackValue(ProjectMetadata.local('fallback', 'Fallback'));
    registerFallbackValue(UploadStatus.pending);
    registerFallbackValue(UploadStatus.uploading);
    registerFallbackValue(UploadStatus.completed);
    registerFallbackValue(UploadStatus.failed);
    registerFallbackValue(
      UploadRecordingRequest(
        name: 'fallback',
        video: RecordingFile(
          filename: 'fallback.mp4',
          contentType: ContentType.mp4,
          sizeBytes: 1,
          timestamp: DateTime.utc(2024, 1, 1),
        ),
        sensors: const [],
      ),
    );
  });

  group('UploadController - unit', () {
    late MockRecordingService recordingService;
    late MockS3Service s3Service;
    late MockLocalMedia localMedia;
    late MockUserPreferenceStorage mockUserPreferenceStorage;

    ProviderContainer buildContainer({
      required AuthState authState,
      HomeState? initialHomeState,
      NetworkStatus? networkStatus,
      UploadController Function(Ref ref, HomeStateNotifier homeStateNotifier)?
      uploadControllerBuilder,
    }) {
      recordingService = MockRecordingService();
      s3Service = MockS3Service();
      localMedia = MockLocalMedia();
      mockUserPreferenceStorage = MockUserPreferenceStorage();

      when(
        () => mockUserPreferenceStorage.isWifiOnly(),
      ).thenAnswer((_) async => false);

      final overrides = <Override>[
        recordingServiceProvider.overrideWithValue(recordingService),
        s3ServiceProvider.overrideWithValue(s3Service),
        localMediaProvider.overrideWithValue(localMedia),
        userPreferenceStorage.overrideWithValue(mockUserPreferenceStorage),
        sessionProvider.overrideWith((ref) => FakeSessionNotifier(authState)),
        homeStateProvider.overrideWith((ref) {
          return TestHomeStateNotifier(initialHomeState ?? HomeState.initial());
        }),
      ];

      if (networkStatus != null) {
        overrides.add(
          networkStatusProvider.overrideWith(
            (ref) => Stream.value(networkStatus),
          ),
        );
      }

      if (uploadControllerBuilder != null) {
        overrides.add(
          uploadControllerProvider.overrideWith((ref) {
            return uploadControllerBuilder(
              ref,
              ref.read(homeStateProvider.notifier),
            );
          }),
        );
      }

      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      return container;
    }

    UploadController buildController(ProviderContainer container) {
      return container.read(uploadControllerProvider);
    }

    group('tryUploads', () {
      test(
        'skips local projects and only schedules non-uploaded recordings',
        () async {
          final localProject = ProjectMetadata.local(
            LocalMedia.defaultProjectId,
            'Default',
          );
          final remoteProject = ProjectMetadata.cloud('p1', 'Remote');

          final pending = MockRecording();
          final uploading = MockRecording();
          final uploaded = MockRecording();

          when(() => pending.id).thenReturn('r1');
          when(() => pending.uploadStatus).thenReturn(UploadStatus.pending);

          when(() => uploading.id).thenReturn('r2');
          when(() => uploading.uploadStatus).thenReturn(UploadStatus.uploading);

          when(() => uploaded.id).thenReturn('r3');
          when(() => uploaded.uploadStatus).thenReturn(UploadStatus.completed);

          late TestUploadController testController;

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              projects: [localProject, remoteProject],
            ),
            uploadControllerBuilder: (ref, homeStateNotifier) {
              testController = TestUploadController(
                ref,
                localMedia,
                recordingService,
                s3Service,
                homeStateNotifier,
              );
              return testController;
            },
          );

          when(
            () => recordingService.getLocalProjectRecordings('p1'),
          ).thenAnswer((_) async => [pending, uploading, uploaded]);

          final controller = container.read(uploadControllerProvider);

          await controller.tryUploads();

          verifyNever(
            () => recordingService.getLocalProjectRecordings(
              LocalMedia.defaultProjectId,
            ),
          );
          verify(
            () => recordingService.getLocalProjectRecordings('p1'),
          ).called(1);

          expect(testController.uploadAndForgetCalls, [('r1', 'p1')]);
        },
      );
    });

    group('uploadAndForget', () {
      test('returns early for guest user', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.guest),
          initialHomeState: HomeState.initial(),
          networkStatus: NetworkStatus.wifi,
        );

        final controller = buildController(container);

        await controller.uploadAndForget('r1', 'p1');

        final state = container.read(homeStateProvider);
        expect(state.recordings, isEmpty);

        verifyNever(
          () => recordingService.deleteLocalRecording(
            projectId: any(named: 'projectId'),
            recordingId: any(named: 'recordingId'),
          ),
        );
      });

      test('returns early when offline', () async {
        final recording = MockRecording();
        when(() => recording.id).thenReturn('r1');
        when(
          () => recording.copyWith(
            name: any(named: 'name'),
            uploadStatus: any(named: 'uploadStatus'),
          ),
        ).thenReturn(recording);

        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial().copyWith(
            recordings: [recording],
          ),
          networkStatus: NetworkStatus.offline,
        );

        final controller = buildController(container);

        await controller.uploadAndForget('r1', 'p1');

        verifyNever(
          () => recording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        );
      });

      test('returns early on mobile when wifi-only is enabled', () async {
        final recording = MockRecording();
        when(() => recording.id).thenReturn('r1');

        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial().copyWith(
            recordings: [recording],
          ),
          networkStatus: NetworkStatus.mobile,
        );

        when(
          () => mockUserPreferenceStorage.isWifiOnly(),
        ).thenAnswer((_) async => true);

        final controller = buildController(container);

        await controller.uploadAndForget('r1', 'p1');

        verifyNever(
          () => recording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        );
        verifyNever(
          () => recordingService.deleteLocalRecording(
            projectId: any(named: 'projectId'),
            recordingId: any(named: 'recordingId'),
          ),
        );
      });

      test('uploads on mobile when wifi-only is disabled', () async {
        final recording = MockRecording();
        final uploadingRecording = MockRecording();
        final failedRecording = MockRecording();

        when(() => recording.id).thenReturn('r1');
        when(
          () => recording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        ).thenReturn(uploadingRecording);

        when(() => uploadingRecording.id).thenReturn('r1');
        when(
          () => uploadingRecording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.failed,
          ),
        ).thenReturn(failedRecording);

        when(() => failedRecording.id).thenReturn('r1');

        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial().copyWith(
            recordings: [recording],
          ),
          networkStatus: NetworkStatus.mobile,
          uploadControllerBuilder: (ref, homeStateNotifier) {
            return NullUploadController(
              ref,
              localMedia,
              recordingService,
              s3Service,
              homeStateNotifier,
            );
          },
        );

        when(
          () => mockUserPreferenceStorage.isWifiOnly(),
        ).thenAnswer((_) async => false);

        final controller = container.read(uploadControllerProvider);

        await controller.uploadAndForget('r1', 'p1');

        verify(
          () => recording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        ).called(1);

        verify(
          () => uploadingRecording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.failed,
          ),
        ).called(1);
      });

      test('marks local upload failed when cleanup throws', () async {
        final oldRecording = MockRecording();
        final uploadingRecording = MockRecording();
        final uploadedRecording = MockRecording();

        when(() => oldRecording.id).thenReturn('r1');
        when(
          () => oldRecording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        ).thenReturn(uploadingRecording);

        when(() => uploadingRecording.id).thenReturn('r1');
        when(() => uploadedRecording.id).thenReturn('uploaded-r1');

        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial().copyWith(
            recordings: [oldRecording],
          ),
          networkStatus: NetworkStatus.wifi,
          uploadControllerBuilder: (ref, homeStateNotifier) {
            return SuccessUploadController(
              ref,
              localMedia,
              recordingService,
              s3Service,
              homeStateNotifier,
              uploadedRecording,
            );
          },
        );

        when(
          () => recordingService.deleteLocalRecording(
            projectId: 'p1',
            recordingId: 'r1',
          ),
        ).thenThrow(Exception('cleanup failed'));

        when(
          () => recordingService.updateLocalUploadStatus(
            'p1',
            'r1',
            UploadStatus.failed,
          ),
        ).thenAnswer((_) async {});

        final controller = container.read(uploadControllerProvider);

        await controller.uploadAndForget('r1', 'p1');

        final state = container.read(homeStateProvider);
        expect(state.recordings, [uploadedRecording]);

        verify(
          () => recordingService.updateLocalUploadStatus(
            'p1',
            'r1',
            UploadStatus.failed,
          ),
        ).called(1);
      });

      test('swallows status update failure after cleanup failure', () async {
        final oldRecording = MockRecording();
        final uploadingRecording = MockRecording();
        final uploadedRecording = MockRecording();

        when(() => oldRecording.id).thenReturn('r1');
        when(
          () => oldRecording.copyWith(
            name: any(named: 'name'),
            uploadStatus: UploadStatus.uploading,
          ),
        ).thenReturn(uploadingRecording);

        when(() => uploadingRecording.id).thenReturn('r1');
        when(() => uploadedRecording.id).thenReturn('uploaded-r1');

        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial().copyWith(
            recordings: [oldRecording],
          ),
          networkStatus: NetworkStatus.wifi,
          uploadControllerBuilder: (ref, homeStateNotifier) {
            return SuccessUploadController(
              ref,
              localMedia,
              recordingService,
              s3Service,
              homeStateNotifier,
              uploadedRecording,
            );
          },
        );

        when(
          () => recordingService.deleteLocalRecording(
            projectId: 'p1',
            recordingId: 'r1',
          ),
        ).thenThrow(Exception('cleanup failed'));

        when(
          () => recordingService.updateLocalUploadStatus(
            'p1',
            'r1',
            UploadStatus.failed,
          ),
        ).thenThrow(Exception('status update failed'));

        final controller = container.read(uploadControllerProvider);

        await controller.uploadAndForget('r1', 'p1');

        verify(
          () => recordingService.updateLocalUploadStatus(
            'p1',
            'r1',
            UploadStatus.failed,
          ),
        ).called(1);
      });

      test(
        'marks recording as failed when uploadRecording returns null',
        () async {
          final recording = MockRecording();
          final uploadingRecording = MockRecording();
          final failedRecording = MockRecording();

          when(() => recording.id).thenReturn('r1');
          when(
            () => recording.copyWith(
              name: any(named: 'name'),
              uploadStatus: UploadStatus.uploading,
            ),
          ).thenReturn(uploadingRecording);

          when(() => uploadingRecording.id).thenReturn('r1');
          when(
            () => uploadingRecording.copyWith(
              name: any(named: 'name'),
              uploadStatus: UploadStatus.failed,
            ),
          ).thenReturn(failedRecording);

          when(() => failedRecording.id).thenReturn('r1');

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              recordings: [recording],
            ),
            networkStatus: NetworkStatus.wifi,
            uploadControllerBuilder: (ref, homeStateNotifier) {
              return NullUploadController(
                ref,
                localMedia,
                recordingService,
                s3Service,
                homeStateNotifier,
              );
            },
          );

          final controller = container.read(uploadControllerProvider);

          await controller.uploadAndForget('r1', 'p1');

          verify(
            () => recording.copyWith(
              name: any(named: 'name'),
              uploadStatus: UploadStatus.uploading,
            ),
          ).called(1);

          verify(
            () => uploadingRecording.copyWith(
              name: any(named: 'name'),
              uploadStatus: UploadStatus.failed,
            ),
          ).called(1);
        },
      );

      test(
        'replaces recording and deletes local recording on success',
        () async {
          final oldRecording = MockRecording();
          final uploadingRecording = MockRecording();
          final uploadedRecording = MockRecording();

          when(() => oldRecording.id).thenReturn('r1');
          when(
            () => oldRecording.copyWith(
              name: any(named: 'name'),
              uploadStatus: UploadStatus.uploading,
            ),
          ).thenReturn(uploadingRecording);

          when(() => uploadingRecording.id).thenReturn('r1');
          when(() => uploadedRecording.id).thenReturn('uploaded-r1');

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              recordings: [oldRecording],
            ),
            networkStatus: NetworkStatus.wifi,
            uploadControllerBuilder: (ref, homeStateNotifier) {
              return SuccessUploadController(
                ref,
                localMedia,
                recordingService,
                s3Service,
                homeStateNotifier,
                uploadedRecording,
              );
            },
          );

          when(
            () => recordingService.deleteLocalRecording(
              projectId: 'p1',
              recordingId: 'r1',
            ),
          ).thenAnswer((_) async => true);

          final controller = container.read(uploadControllerProvider);

          await controller.uploadAndForget('r1', 'p1');

          final state = container.read(homeStateProvider);
          expect(state.recordings, [uploadedRecording]);

          verify(
            () => recordingService.deleteLocalRecording(
              projectId: 'p1',
              recordingId: 'r1',
            ),
          ).called(1);
        },
      );
    });

    group('uploadRecording', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('upload_controller_test');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('returns null when video file does not exist', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = File('${tempDir.path}/missing.mp4');
        final meta = writeTempFile(
          tempDir,
          'meta.json',
          jsonEncode({
            'name': 'Test recording',
            'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
          }),
        );

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test('returns null when meta file does not exist', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = File('${tempDir.path}/missing_meta.json');

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test('returns null when meta json is invalid', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = writeTempFile(tempDir, 'meta.json', '{invalid json');

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test('returns null when meta name is blank', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = writeTempFile(
          tempDir,
          'meta.json',
          jsonEncode({
            'name': '   ',
            'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
          }),
        );

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test('returns null when startUpload throws DioException', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = writeTempFile(
          tempDir,
          'meta.json',
          jsonEncode({
            'name': 'Test recording',
            'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
          }),
        );
        final thumbnail = File('${tempDir.path}/thumb.jpg');

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);
        when(() => localMedia.thumbnailFile('p1', 'r1')).thenReturn(thumbnail);

        when(
          () => recordingService.getLocalRecordingSensors('p1', 'r1'),
        ).thenAnswer((_) async => <Sensor>[]);

        when(() => recordingService.startUpload(any())).thenThrow(dioEx(500));

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test('returns null when startUpload throws generic exception', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = writeTempFile(
          tempDir,
          'meta.json',
          jsonEncode({
            'name': 'Test recording',
            'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
          }),
        );
        final thumbnail = File('${tempDir.path}/thumb.jpg');

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);
        when(() => localMedia.thumbnailFile('p1', 'r1')).thenReturn(thumbnail);

        when(
          () => recordingService.getLocalRecordingSensors('p1', 'r1'),
        ).thenAnswer((_) async => <Sensor>[]);

        when(
          () => recordingService.startUpload(any()),
        ).thenThrow(Exception('boom'));

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);
      });

      test(
        'maps default project id to null and uses fallback timestamp when timestamp is invalid',
        () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial(),
          );

          final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3, 4]);
          final meta = writeTempFile(
            tempDir,
            'meta.json',
            jsonEncode({'name': 'Test recording', 'timestamp': 'not-a-date'}),
          );
          final missingThumbnail = File('${tempDir.path}/missing_thumb.jpg');

          when(
            () => localMedia.videoFile(LocalMedia.defaultProjectId, 'r1'),
          ).thenReturn(video);
          when(
            () =>
                localMedia.recordingMetaFile(LocalMedia.defaultProjectId, 'r1'),
          ).thenReturn(meta);
          when(
            () => localMedia.thumbnailFile(LocalMedia.defaultProjectId, 'r1'),
          ).thenReturn(missingThumbnail);

          when(
            () => recordingService.getLocalRecordingSensors(
              LocalMedia.defaultProjectId,
              'r1',
            ),
          ).thenAnswer((_) async => <Sensor>[]);

          when(
            () => recordingService.startUpload(any()),
          ).thenThrow(Exception('stop after request capture'));

          final controller = buildController(container);

          final result = await controller.uploadRecording(
            recordingId: 'r1',
            projectId: LocalMedia.defaultProjectId,
          );

          expect(result, isNull);

          final captured =
              verify(
                    () => recordingService.startUpload(captureAny()),
                  ).captured.single
                  as UploadRecordingRequest;

          expect(captured.name, 'Test recording');
          expect(captured.projectId, isNull);
          expect(captured.thumbnailContent, isNull);
          expect(captured.video.sizeBytes, 4);
          expect(captured.video.filename, 'video.mp4');
          expect(captured.video.timestamp, isA<DateTime>());
        },
      );

      test('returns null when a sensor file is missing', () async {
        final container = buildContainer(
          authState: const AuthState(mode: AuthMode.authenticated),
          initialHomeState: HomeState.initial(),
        );

        final video = writeTempBytesFile(tempDir, 'video.mp4', [1, 2, 3]);
        final meta = writeTempFile(
          tempDir,
          'meta.json',
          jsonEncode({
            'name': 'Test recording',
            'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
          }),
        );

        final sensor = MockSensor();
        when(() => sensor.sensorIndex).thenReturn(0);
        when(() => sensor.name).thenReturn('Heart rate');
        when(() => sensor.timeStamp).thenReturn(DateTime.utc(2024, 1, 1));
        when(
          () => sensor.localPath,
        ).thenReturn('${tempDir.path}/missing_sensor.json');

        when(() => localMedia.videoFile('p1', 'r1')).thenReturn(video);
        when(() => localMedia.recordingMetaFile('p1', 'r1')).thenReturn(meta);
        when(
          () => localMedia.thumbnailFile('p1', 'r1'),
        ).thenReturn(File('${tempDir.path}/missing_thumb.jpg'));

        when(
          () => recordingService.getLocalRecordingSensors('p1', 'r1'),
        ).thenAnswer((_) async => [sensor]);

        final controller = buildController(container);

        final result = await controller.uploadRecording(
          recordingId: 'r1',
          projectId: 'p1',
        );

        expect(result, isNull);

        verifyNever(() => recordingService.startUpload(any()));
      });
    });
  });
}
