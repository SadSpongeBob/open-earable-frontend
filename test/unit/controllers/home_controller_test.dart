import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/project/project_user.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/controllers/home_controller.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/home_state.dart';

class MockProjectService extends Mock implements ProjectService {}

class MockRecordingService extends Mock implements RecordingService {}

class MockUserService extends Mock implements UserService {}

class MockLocalMedia extends Mock implements LocalMedia {}

class MockProject extends Mock implements Project {}

class MockRecording extends Mock implements Recording {}

class MockProjectUser extends Mock implements ProjectUser {}

class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(AuthState initial) : super() {
    state = initial;
  }
}

DioException dioEx(int statusCode) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: statusCode,
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(<Recording>[]);
    registerFallbackValue(<ProjectMetadata>[]);
    registerFallbackValue(ProjectMetadata.local('fallback', 'Fallback'));
    registerFallbackValue(ProjectRoleType.viewer);
  });

  group('HomeController - unit', () {
    late MockProjectService projectService;
    late MockRecordingService recordingService;
    late MockUserService userService;
    late MockLocalMedia localMedia;

    ProviderContainer buildContainer({
      required AuthState authState,
      HomeState? initialHomeState,
    }) {
      projectService = MockProjectService();
      recordingService = MockRecordingService();
      userService = MockUserService();
      localMedia = MockLocalMedia();

      final overrides = <Override>[
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        userServiceProvider.overrideWithValue(userService),
        localMediaProvider.overrideWithValue(localMedia),
        sessionProvider.overrideWith((ref) => FakeSessionNotifier(authState)),
        homeStateProvider.overrideWith((ref) {
          final notifier = HomeStateNotifier();
          if (initialHomeState != null) {
            notifier.state = initialHomeState;
          }
          return notifier;
        }),
      ];

      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      return container;
    }

    HomeController buildController(ProviderContainer container) {
      return container.read(homeControllerProvider);
    }

    test('enterSelectionMode excludes Default project id', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      controller.enterSelectionMode(
        initialProjectId: LocalMedia.defaultProjectId,
      );

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isFalse);
      expect(state.selectedProjectIds, isEmpty);
    });

    test('enterSelectionMode selects non-default project id', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      controller.enterSelectionMode(initialProjectId: 'p1');

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isTrue);
      expect(state.selectedProjectIds, {'p1'});
    });

    test('toggleProjectSelection ignores Default project id', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      controller.toggleProjectSelection(LocalMedia.defaultProjectId);

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isFalse);
      expect(state.selectedProjectIds, isEmpty);
    });

    test(
        'toggleProjectSelection adds id when not selected, removes when selected',
            () {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
          );
          final controller = buildController(container);

          controller.toggleProjectSelection('p1');
          var state = container.read(homeStateProvider);
          expect(state.selectedProjectIds, {'p1'});
          expect(state.isProjectSelectionMode, isTrue);

          controller.toggleProjectSelection('p1');
          state = container.read(homeStateProvider);
          expect(state.selectedProjectIds, isEmpty);
          expect(state.isProjectSelectionMode, isFalse);
        });

    test('handleProjectLongPress ignores Default project id', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      controller.handleProjectLongPress(LocalMedia.defaultProjectId);

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isFalse);
      expect(state.selectedProjectIds, isEmpty);
    });

    test(
        'handleProjectLongPress enters selection mode when not already in selection mode',
            () {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
          );
          final controller = buildController(container);

          controller.handleProjectLongPress('p1');

          final state = container.read(homeStateProvider);
          expect(state.isProjectSelectionMode, isTrue);
          expect(state.selectedProjectIds, {'p1'});
        });

    test('handleProjectLongPress does nothing when already in selection mode',
            () {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              isProjectSelectionMode: true,
              selectedProjectIds: {'p1'},
            ),
          );
          final controller = buildController(container);

          controller.handleProjectLongPress('p2');

          final state = container.read(homeStateProvider);
          expect(state.selectedProjectIds, {'p1'});
        });

    test('exitProjectSelectionMode clears selection', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          isProjectSelectionMode: true,
          selectedProjectIds: {'p1'},
        ),
      );
      final controller = buildController(container);

      controller.exitProjectSelectionMode();

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isFalse);
      expect(state.selectedProjectIds, isEmpty);
    });

    test(
        'loadProjects guest: loads local, adds Default (local), opens Default, sets loaded',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              openProjectId: LocalMedia.defaultProjectId,
              areProjectsLoaded: false,
            ),
          );
          final controller = buildController(container);

          when(() => projectService.getLocalProjects()).thenAnswer(
                (_) async => [
              ProjectMetadata.local('lp1', 'Local 1'),
              ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default Duplicate'),
            ],
          );

          when(() => recordingService.getLocalProjectRecordings(any()))
              .thenAnswer((_) async => <Recording>[]);

          await controller.loadProjects();

          verify(() => projectService.getLocalProjects()).called(1);
          verifyNever(() => projectService.getProjects());

          final state = container.read(homeStateProvider);

          expect(state.areProjectsLoaded, isTrue);
          expect(state.openProjectId, LocalMedia.defaultProjectId);

          expect(state.projects.first.id, LocalMedia.defaultProjectId);
          expect(state.projects.first.projectSource, ProjectSource.local);
          expect(
            state.projects.where((p) => p.id == LocalMedia.defaultProjectId).length,
            1,
          );
        });

    test(
        'loadProjects authenticated: loads local+cloud, adds Default (cloud), opens current if still valid',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              openProjectId: 'cp1',
              areProjectsLoaded: false,
            ),
          );
          final controller = buildController(container);

          when(() => projectService.getLocalProjects()).thenAnswer(
                (_) async => [ProjectMetadata.local('lp1', 'Local 1')],
          );
          when(() => projectService.getProjects()).thenAnswer(
                (_) async => [ProjectMetadata.cloud('cp1', 'Cloud 1')],
          );

          when(() => recordingService.getLocalProjectRecordings(any()))
              .thenAnswer((_) async => <Recording>[]);

          final proj = MockProject();
          when(() => proj.recordings).thenReturn(<Recording>[]);
          when(() => projectService.getProject('cp1')).thenAnswer((_) async => proj);

          await controller.loadProjects();

          verify(() => projectService.getLocalProjects()).called(1);
          verify(() => projectService.getProjects()).called(1);
          verify(() => projectService.getProject('cp1')).called(1);

          final state = container.read(homeStateProvider);

          expect(state.areProjectsLoaded, isTrue);
          expect(state.openProjectId, 'cp1');

          expect(state.projects.first.id, LocalMedia.defaultProjectId);
          expect(state.projects.first.projectSource, ProjectSource.cloud);
          expect(state.projects.any((p) => p.id == 'lp1'), isTrue);
          expect(state.projects.any((p) => p.id == 'cp1'), isTrue);
        });

    test(
        'loadProjects authenticated: opens Default when current open project id is missing',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              openProjectId: 'missing',
              areProjectsLoaded: false,
            ),
          );
          final controller = buildController(container);

          when(() => projectService.getLocalProjects()).thenAnswer(
                (_) async => [ProjectMetadata.local('lp1', 'Local 1')],
          );
          when(() => projectService.getProjects()).thenAnswer(
                (_) async => [ProjectMetadata.cloud('cp1', 'Cloud 1')],
          );

          when(() => recordingService.getLocalProjectRecordings(any()))
              .thenAnswer((_) async => <Recording>[]);

          when(() => recordingService.getRecordings())
              .thenAnswer((_) async => <Recording>[]);

          await controller.loadProjects();

          final state = container.read(homeStateProvider);
          expect(state.openProjectId, LocalMedia.defaultProjectId);
        });

    test('openProject invalid id -> does not call services', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local('p1', 'P1')],
          openProjectId: 'p1',
        ),
      );
      final controller = buildController(container);

      await controller.openProject('missing');

      verifyNever(() => recordingService.getLocalProjectRecordings(any()));
      verifyNever(() => projectService.getProject(any()));
      verifyNever(() => recordingService.getRecordings());
    });

    test(
        'handleProjectTap in selection mode toggles selection and does not open project',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
                ProjectMetadata.local('p2', 'P2'),
              ],
              openProjectId: 'p1',
              selectedProjectIds: {'p2'},
              isProjectSelectionMode: true,
            ),
          );
          final controller = buildController(container);

          await controller.handleProjectTap('p1');

          final state = container.read(homeStateProvider);
          expect(state.selectedProjectIds, {'p2', 'p1'});

          verifyNever(() => recordingService.getLocalProjectRecordings(any()));
        });

    test(
        'handleProjectTap not in selection mode opens project and does not toggle selection',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
                ProjectMetadata.local('p2', 'P2'),
              ],
              openProjectId: 'p1',
              selectedProjectIds: {'p2'},
              isProjectSelectionMode: false,
            ),
          );
          final controller = buildController(container);

          when(() => recordingService.getLocalProjectRecordings('p2'))
              .thenAnswer((_) async => <Recording>[]);

          await controller.handleProjectTap('p2');

          final state = container.read(homeStateProvider);
          expect(state.selectedProjectIds, {'p2'});

          verify(() => recordingService.getLocalProjectRecordings('p2')).called(1);
        });

    test('createProject: empty name -> does not call services or change list',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
            ),
          );
          final controller = buildController(container);

          await controller.createProject('   ');

          verifyNever(
                () => projectService.createLocalProject(name: any(named: 'name')),
          );
          verifyNever(() => projectService.createProject(any()));
          final state = container.read(homeStateProvider);
          expect(state.projects.length, 1);
        });

    test('createProject: duplicate name -> does not call services', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'My Project'),
          ],
        ),
      );
      final controller = buildController(container);

      await controller.createProject(' my project ');

      verifyNever(
            () => projectService.createLocalProject(name: any(named: 'name')),
      );
      verifyNever(() => projectService.createProject(any()));
      final state = container.read(homeStateProvider);
      expect(state.projects.any((p) => p.name == 'My Project'), isTrue);
      expect(state.projects.length, 2);
    });

    test('createProject guest: calls createLocalProject and adds it', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
        ),
      );
      final controller = buildController(container);

      when(() => projectService.createLocalProject(name: 'New'))
          .thenAnswer((_) async => ProjectMetadata.local('p-new', 'New'));

      await controller.createProject(' New ');

      verify(() => projectService.createLocalProject(name: 'New')).called(1);
      final state = container.read(homeStateProvider);
      expect(state.projects.any((p) => p.id == 'p-new'), isTrue);
    });

    test('createProject authenticated: calls createProject and adds metadata',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              projects: [ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default')],
            ),
          );
          final controller = buildController(container);

          final proj = MockProject();
          when(() => proj.toMetadata())
              .thenReturn(ProjectMetadata.cloud('cp-new', 'Cloud New'));
          when(() => projectService.createProject('Cloud New'))
              .thenAnswer((_) async => proj);

          await controller.createProject('Cloud New');

          verify(() => projectService.createProject('Cloud New')).called(1);
          final state = container.read(homeStateProvider);
          expect(state.projects.any((p) => p.id == 'cp-new'), isTrue);
        });

    test('renameProject: empty name -> does not call services', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
          ],
        ),
      );
      final controller = buildController(container);

      await controller.renameProject('p1', '   ');

      verifyNever(() => projectService.renameProject(any(), any()));
      verifyNever(
            () => projectService.updateLocalProject(project: any(named: 'project')),
      );
      final state = container.read(homeStateProvider);
      expect(state.projects.firstWhere((p) => p.id == 'p1').name, 'P1');
    });

    test('renameProject: duplicate name -> does not call services', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'Alpha'),
            ProjectMetadata.local('p2', 'Beta'),
          ],
        ),
      );
      final controller = buildController(container);

      await controller.renameProject('p2', ' alpha ');

      verifyNever(() => projectService.renameProject(any(), any()));
      verifyNever(
            () => projectService.updateLocalProject(project: any(named: 'project')),
      );
      final state = container.read(homeStateProvider);
      expect(state.projects.firstWhere((p) => p.id == 'p2').name, 'Beta');
    });

    test('renameProject: invalid id -> does not call services', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local('p1', 'P1')],
        ),
      );
      final controller = buildController(container);

      await controller.renameProject('missing', 'New Name');

      verifyNever(() => projectService.renameProject(any(), any()));
      verifyNever(
            () => projectService.updateLocalProject(project: any(named: 'project')),
      );
    });

    test('renameProject local: updates local project and state list', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'Old'),
          ],
        ),
      );
      final controller = buildController(container);

      when(() => projectService.updateLocalProject(project: any(named: 'project')))
          .thenAnswer((_) async {});

      await controller.renameProject('p1', 'New');

      verify(() => projectService.updateLocalProject(project: any(named: 'project'))).called(1);
      verifyNever(() => projectService.renameProject(any(), any()));
      final state = container.read(homeStateProvider);
      expect(state.projects.firstWhere((p) => p.id == 'p1').name, 'New');
    });

    test('renameProject cloud as guest: calls renameProject and updateLocalProject',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud Old'),
              ],
            ),
          );
          final controller = buildController(container);

          when(() => projectService.renameProject('cp1', 'Cloud New'))
              .thenAnswer((_) async {});
          when(() => projectService.updateLocalProject(project: any(named: 'project')))
              .thenAnswer((_) async {});

          await controller.renameProject('cp1', 'Cloud New');

          verify(() => projectService.renameProject('cp1', 'Cloud New')).called(1);
          verify(() => projectService.updateLocalProject(project: any(named: 'project'))).called(1);
          final state = container.read(homeStateProvider);
          expect(state.projects.firstWhere((p) => p.id == 'cp1').name, 'Cloud New');
        });

    test(
        'deleteProjects: ignores Default id, deletes local project, and if open -> opens Default',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
              openProjectId: 'p1',
            ),
          );
          final controller = buildController(container);

          when(() => projectService.deleteLocalProject('p1')).thenAnswer((_) async {});
          when(() => recordingService.getLocalProjectRecordings(LocalMedia.defaultProjectId))
              .thenAnswer((_) async => <Recording>[]);

          await controller.deleteProjects({LocalMedia.defaultProjectId, 'p1'});

          verify(() => projectService.deleteLocalProject('p1')).called(1);
          final state = container.read(homeStateProvider);
          expect(state.projects.any((p) => p.id == 'p1'), isFalse);
          expect(state.openProjectId, LocalMedia.defaultProjectId);
        });

    test(
        'duplicateProjects: skips Default id, duplicates local project via duplicateLocalProject + adds new project',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
            ),
          );
          final controller = buildController(container);

          when(() => projectService.duplicateLocalProject(any(), any()))
              .thenAnswer((_) async {});

          await controller.duplicateProjects({LocalMedia.defaultProjectId, 'p1'});

          verify(() => projectService.duplicateLocalProject('p1', any())).called(1);

          final state = container.read(homeStateProvider);
          expect(state.projects.length, 3);
          expect(state.projects.where((p) => p.id == 'p1').length, 1);
          expect(
            state.projects.where((p) => p.id != LocalMedia.defaultProjectId && p.id != 'p1').length,
            1,
          );
        });

    test('toggleRecordingSelection adds/removes and selection mode reflects emptiness',
            () {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
          );
          final controller = buildController(container);

          controller.toggleRecordingSelection('r1');
          var state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, {'r1'});
          expect(state.isRecordingSelectionMode, isTrue);

          controller.toggleRecordingSelection('r1');
          state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test('handleRecordingTap does nothing when not in selection mode', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          selectedRecordingIds: {'r1'},
          isRecordingSelectionMode: false,
        ),
      );
      final controller = buildController(container);

      controller.handleRecordingTap('r1');

      final state = container.read(homeStateProvider);
      expect(state.selectedRecordingIds, {'r1'});
      expect(state.isRecordingSelectionMode, isFalse);
    });

    test('handleRecordingTap toggles selection and exits when empty', () {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          selectedRecordingIds: {'r1'},
          isRecordingSelectionMode: true,
        ),
      );
      final controller = buildController(container);

      controller.handleRecordingTap('r1');

      final state = container.read(homeStateProvider);
      expect(state.selectedRecordingIds, isEmpty);
      expect(state.isRecordingSelectionMode, isFalse);
    });

    test('handleGoToRecordingTap calls callback when allowed (guest, Default project)',
            () async {
          var called = false;
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
              openProjectId: LocalMedia.defaultProjectId,
            ),
          );
          final controller = buildController(container);

          await controller.handleGoToRecordingTap(goToRecording: () => called = true);

          expect(called, isTrue);
        });

    test('deleteRecordings: empty set -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      await controller.deleteRecordings({});

      verifyNever(
            () => recordingService.deleteLocalRecording(
          projectId: any(named: 'projectId'),
          recordingId: any(named: 'recordingId'),
        ),
      );
      verifyNever(() => recordingService.deleteCloudRecording(any()));
    });

    test(
        'deleteRecordings: deletes local + cloud, refreshes open project, clears selection',
            () async {
          final rLocal = MockRecording();
          when(() => rLocal.id).thenReturn('r-local');
          when(() => rLocal.name).thenReturn('LocalRec');
          when(() => rLocal.isLocal).thenReturn(true);
          when(() => rLocal.source).thenReturn(RecordingSource.local);

          final rCloud = MockRecording();
          when(() => rCloud.id).thenReturn('r-cloud');
          when(() => rCloud.name).thenReturn('CloudRec');
          when(() => rCloud.isLocal).thenReturn(false);
          when(() => rCloud.source).thenReturn(RecordingSource.cloud);

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
              openProjectId: 'p1',
              recordings: [rLocal, rCloud],
              isRecordingSelectionMode: true,
              selectedRecordingIds: {'r-local', 'r-cloud'},
            ),
          );
          final controller = buildController(container);

          when(
                () => recordingService.deleteLocalRecording(
              projectId: 'p1',
              recordingId: 'r-local',
            ),
          ).thenAnswer((_) async => true);

          when(() => recordingService.deleteCloudRecording('r-cloud'))
              .thenAnswer((_) async {});

          when(() => recordingService.getLocalProjectRecordings('p1'))
              .thenAnswer((_) async => <Recording>[]);

          await controller.deleteRecordings({'r-local', 'r-cloud'});

          verify(
                () => recordingService.deleteLocalRecording(
              projectId: 'p1',
              recordingId: 'r-local',
            ),
          ).called(1);
          verify(() => recordingService.deleteCloudRecording('r-cloud')).called(1);
          verify(() => recordingService.getLocalProjectRecordings('p1'))
              .called(greaterThanOrEqualTo(1));

          final state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test('duplicateRecordings: empty set -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      await controller.duplicateRecordings({});

      verifyNever(
            () => recordingService.duplicateLocalRecording(
          projectId: any(named: 'projectId'),
          sourceRecordingId: any(named: 'sourceRecordingId'),
          newRecordingId: any(named: 'newRecordingId'),
          newName: any(named: 'newName'),
        ),
      );
      verifyNever(
            () => recordingService.duplicateCloudRecordings(
          recordingIds: any(named: 'recordingIds'),
          projectId: any(named: 'projectId'),
        ),
      );
    });

    test(
        'duplicateRecordings: duplicates local + cloud, refreshes open project, clears selection',
            () async {
          final rLocal = MockRecording();
          when(() => rLocal.id).thenReturn('r-local');
          when(() => rLocal.name).thenReturn('LocalRec');
          when(() => rLocal.isLocal).thenReturn(true);
          when(() => rLocal.source).thenReturn(RecordingSource.local);

          final rCloud = MockRecording();
          when(() => rCloud.id).thenReturn('r-cloud');
          when(() => rCloud.name).thenReturn('CloudRec');
          when(() => rCloud.isLocal).thenReturn(false);
          when(() => rCloud.source).thenReturn(RecordingSource.cloud);

          final dupCloud1 = MockRecording();
          when(() => dupCloud1.id).thenReturn('r-cloud-dup1');
          when(() => dupCloud1.name).thenReturn('CloudRec (Copy)');
          when(() => dupCloud1.isLocal).thenReturn(false);
          when(() => dupCloud1.source).thenReturn(RecordingSource.cloud);

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
              openProjectId: 'p1',
              recordings: [rLocal, rCloud],
              isRecordingSelectionMode: true,
              selectedRecordingIds: {'r-local', 'r-cloud'},
            ),
          );
          final controller = buildController(container);

          when(
                () => recordingService.duplicateLocalRecording(
              projectId: 'p1',
              sourceRecordingId: 'r-local',
              newRecordingId: any(named: 'newRecordingId'),
              newName: any(named: 'newName'),
            ),
          ).thenAnswer((_) async => true);

          when(
                () => recordingService.duplicateCloudRecordings(
              recordingIds: ['r-cloud'],
              projectId: 'p1',
            ),
          ).thenAnswer((_) async => [dupCloud1]);

          when(() => recordingService.getLocalProjectRecordings('p1'))
              .thenAnswer((_) async => <Recording>[]);

          await controller.duplicateRecordings({'r-local', 'r-cloud'});

          verify(
                () => recordingService.duplicateLocalRecording(
              projectId: 'p1',
              sourceRecordingId: 'r-local',
              newRecordingId: any(named: 'newRecordingId'),
              newName: any(named: 'newName'),
            ),
          ).called(1);

          verify(
                () => recordingService.duplicateCloudRecordings(
              recordingIds: ['r-cloud'],
              projectId: 'p1',
            ),
          ).called(1);

          verify(() => recordingService.getLocalProjectRecordings('p1'))
              .called(greaterThanOrEqualTo(1));

          final state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test('moveRecordings: empty set -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
      );
      final controller = buildController(container);

      await controller.moveRecordings({}, targetProjectId: 'p2');

      verifyNever(
            () => projectService.moveRecordings(
          recordingIds: any(named: 'recordingIds'),
          targetProjectId: any(named: 'targetProjectId'),
        ),
      );
    });

    test('moveRecordings: same source/target -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          openProjectId: 'p1',
        ),
      );
      final controller = buildController(container);

      await controller.moveRecordings({'r1'}, targetProjectId: 'p1');

      verifyNever(
            () => projectService.moveRecordings(
          recordingIds: any(named: 'recordingIds'),
          targetProjectId: any(named: 'targetProjectId'),
        ),
      );
    });

    test(
        'moveRecordings: cloud recordings to Default project calls projectService.moveRecordings with null target',
            () async {
          final rCloud = MockRecording();
          when(() => rCloud.id).thenReturn('r-cloud');
          when(() => rCloud.name).thenReturn('CloudRec');
          when(() => rCloud.isLocal).thenReturn(false);
          when(() => rCloud.source).thenReturn(RecordingSource.cloud);

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud P1'),
              ],
              openProjectId: 'cp1',
              recordings: [rCloud],
              isRecordingSelectionMode: true,
              selectedRecordingIds: {'r-cloud'},
            ),
          );
          final controller = buildController(container);

          when(
                () => projectService.moveRecordings(
              recordingIds: ['r-cloud'],
              targetProjectId: null,
            ),
          ).thenAnswer((_) async {});

          when(() => recordingService.getLocalProjectRecordings('cp1'))
              .thenAnswer((_) async => <Recording>[]);

          final proj = MockProject();
          when(() => proj.recordings).thenReturn(<Recording>[]);
          when(() => projectService.getProject('cp1')).thenAnswer((_) async => proj);

          await controller.moveRecordings(
            {'r-cloud'},
            targetProjectId: LocalMedia.defaultProjectId,
          );

          verify(
                () => projectService.moveRecordings(
              recordingIds: ['r-cloud'],
              targetProjectId: null,
            ),
          ).called(1);

          final state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test(
        'clearUsersPopupState clears users popup state (loading=false, users cleared, error cleared)',
            () {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              isUsersLoading: true,
              projectUsers: const [],
              usersErrorMessage: 'some error',
            ),
          );
          final controller = buildController(container);

          controller.clearUsersPopupState();

          final state = container.read(homeStateProvider);
          expect(state.isUsersLoading, isFalse);
          expect(state.usersErrorMessage, isNull);
          expect(state.projectUsers, isEmpty);
        });

    test('loadProjects returns early when already loaded', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          areProjectsLoaded: true,
        ),
      );
      final controller = buildController(container);

      await controller.loadProjects();

      verifyNever(() => projectService.getLocalProjects());
      verifyNever(() => projectService.getProjects());
      verifyNever(() => recordingService.getLocalProjectRecordings(any()));
    });

    test('loadProjects sets error when getLocalProjects throws', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          areProjectsLoaded: false,
        ),
      );
      final controller = buildController(container);

      when(() => projectService.getLocalProjects()).thenThrow(Exception('boom'));

      await controller.loadProjects();

      final state = container.read(homeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('openProject local project loads local recordings and sets open project',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
              openProjectId: LocalMedia.defaultProjectId,
            ),
          );
          final controller = buildController(container);

          when(() => recordingService.getLocalProjectRecordings('p1'))
              .thenAnswer((_) async => <Recording>[]);

          await controller.openProject('p1');

          verify(() => recordingService.getLocalProjectRecordings('p1')).called(1);
          verifyNever(() => recordingService.getRecordings());
          verifyNever(() => projectService.getProject(any()));

          final state = container.read(homeStateProvider);
          expect(state.openProjectId, 'p1');
        });

    test('openProject cloud DEFAULT: merges local + cloud recordings (getRecordings)',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
              ],
              openProjectId: 'x',
            ),
          );
          final controller = buildController(container);

          final local = MockRecording();
          when(() => local.id).thenReturn('l1');
          when(() => recordingService.getLocalProjectRecordings(LocalMedia.defaultProjectId))
              .thenAnswer((_) async => <Recording>[local]);

          final cloud = MockRecording();
          when(() => cloud.id).thenReturn('c1');
          when(() => recordingService.getRecordings()).thenAnswer((_) async => <Recording>[cloud]);

          await controller.openProject(LocalMedia.defaultProjectId);

          verify(() => recordingService.getLocalProjectRecordings(LocalMedia.defaultProjectId))
              .called(1);
          verify(() => recordingService.getRecordings()).called(1);

          final state = container.read(homeStateProvider);
          expect(state.openProjectId, LocalMedia.defaultProjectId);
          expect(state.recordings.length, 2);
        });

    test('openProject cloud DEFAULT: getRecordings throws -> keeps only local recordings',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
              ],
              openProjectId: 'x',
            ),
          );
          final controller = buildController(container);

          final local = MockRecording();
          when(() => local.id).thenReturn('l1');

          when(() => recordingService.getLocalProjectRecordings(LocalMedia.defaultProjectId))
              .thenAnswer((_) async => <Recording>[local]);

          when(() => recordingService.getRecordings()).thenThrow(Exception('fail'));

          await controller.openProject(LocalMedia.defaultProjectId);

          final state = container.read(homeStateProvider);
          expect(state.recordings.length, 1);
          expect(state.recordings.first.id, 'l1');
        });

    test(
        'openProject cloud NON-default: merges local + project.getProject(projectId).recordings',
            () async {
          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.authenticated),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
              openProjectId: LocalMedia.defaultProjectId,
            ),
          );
          final controller = buildController(container);

          final local = MockRecording();
          when(() => local.id).thenReturn('l1');
          when(() => recordingService.getLocalProjectRecordings('cp1'))
              .thenAnswer((_) async => <Recording>[local]);

          final cloud = MockRecording();
          when(() => cloud.id).thenReturn('c1');

          final proj = MockProject();
          when(() => proj.recordings).thenReturn(<Recording>[cloud]);
          when(() => projectService.getProject('cp1')).thenAnswer((_) async => proj);

          await controller.openProject('cp1');

          verify(() => recordingService.getLocalProjectRecordings('cp1')).called(1);
          verify(() => projectService.getProject('cp1')).called(1);

          final state = container.read(homeStateProvider);
          expect(state.openProjectId, 'cp1');
          expect(state.recordings.length, 2);
        });

    test('handleProjectTap does nothing when tapping already open project', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
          ],
          openProjectId: 'p1',
          isProjectSelectionMode: false,
        ),
      );
      final controller = buildController(container);

      await controller.handleProjectTap('p1');

      verifyNever(() => recordingService.getLocalProjectRecordings(any()));
    });

    test('createProject sets error when service throws', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
        ),
      );
      final controller = buildController(container);

      when(() => projectService.createLocalProject(name: 'New'))
          .thenThrow(Exception('fail'));

      await controller.createProject('New');

      final state = container.read(homeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('renameProject cloud authenticated: no role -> no permission (no calls)',
            () async {
          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
            ),
          );
          final controller = buildController(container);

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[]);

          await controller.renameProject('cp1', 'New');

          verify(() => projectService.getProjectUsers('cp1')).called(1);
          verifyNever(() => projectService.renameProject(any(), any()));
          verifyNever(
                () => projectService.updateLocalProject(project: any(named: 'project')),
          );
        });

    test(
        'renameProject cloud authenticated: role Owner/Editor -> renameProject + updateLocalProject',
            () async {
          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
            ),
          );
          final controller = buildController(container);

          final me = MockProjectUser();
          when(() => me.userId).thenReturn('me');
          when(() => me.role).thenReturn(
            Owner(userId: 'me'),
          );

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[me]);

          when(() => projectService.renameProject('cp1', 'New'))
              .thenAnswer((_) async {});
          when(() => projectService.updateLocalProject(project: any(named: 'project')))
              .thenAnswer((_) async {});

          await controller.renameProject('cp1', 'New');

          verify(() => projectService.getProjectUsers('cp1')).called(1);
          verify(() => projectService.renameProject('cp1', 'New')).called(1);
          verify(() => projectService.updateLocalProject(project: any(named: 'project')))
              .called(1);

          final state = container.read(homeStateProvider);
          expect(state.projects.firstWhere((p) => p.id == 'cp1').name, 'New');
        });

    test('deleteProjects cloud authenticated Owner: calls deleteProject + deleteLocalProject',
            () async {
          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
              openProjectId: LocalMedia.defaultProjectId,
            ),
          );
          final controller = buildController(container);

          final me = MockProjectUser();
          when(() => me.userId).thenReturn('me');
          when(() => me.role).thenReturn(
            Owner(userId: 'me'),
          );

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[me]);
          when(() => projectService.deleteProject('cp1')).thenAnswer((_) async {});
          when(() => projectService.deleteLocalProject('cp1')).thenAnswer((_) async {});

          await controller.deleteProjects({'cp1'});

          verify(() => projectService.getProjectUsers('cp1')).called(1);
          verify(() => projectService.deleteProject('cp1')).called(1);
          verify(() => projectService.deleteLocalProject('cp1')).called(1);
        });

    test(
        'deleteProjects cloud authenticated non-Owner: calls leaveProject + deleteLocalProject',
            () async {
          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
            ),
          );
          final controller = buildController(container);

          final me = MockProjectUser();
          when(() => me.userId).thenReturn('me');
          when(() => me.role).thenReturn(
            Viewer(userId: 'me'),
          );

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[me]);
          when(() => projectService.leaveProject(projectId: 'cp1'))
              .thenAnswer((_) async {});
          when(() => projectService.deleteLocalProject('cp1')).thenAnswer((_) async {});

          await controller.deleteProjects({'cp1'});

          verify(() => projectService.leaveProject(projectId: 'cp1')).called(1);
          verify(() => projectService.deleteLocalProject('cp1')).called(1);
          verifyNever(() => projectService.deleteProject(any()));
        });

    test(
        'duplicateProjects cloud authenticated: role Owner/Editor -> duplicateProject + duplicateLocalProject + add',
            () async {
          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
            ),
          );
          final controller = buildController(container);

          final me = MockProjectUser();
          when(() => me.userId).thenReturn('me');
          when(() => me.role).thenReturn(
            Editor(userId: 'me'),
          );

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[me]);

          when(() => projectService.duplicateProject('cp1'))
              .thenAnswer((_) async => ProjectMetadata.cloud('cp2', 'Cloud 2'));

          when(() => projectService.duplicateLocalProject('cp1', any()))
              .thenAnswer((_) async {});

          await controller.duplicateProjects({'cp1'});

          verify(() => projectService.getProjectUsers('cp1')).called(1);
          verify(() => projectService.duplicateProject('cp1')).called(1);
          verify(() => projectService.duplicateLocalProject('cp1', any())).called(1);

          final state = container.read(homeStateProvider);
          expect(state.projects.any((p) => p.id == 'cp2'), isTrue);
        });

    test('handleRecordingLongPress no permission -> does not enter selection mode', () async {
      final r = MockRecording();
      when(() => r.id).thenReturn('r1');
      when(() => r.name).thenReturn('R1');
      when(() => r.isLocal).thenReturn(false);
      when(() => r.source).thenReturn(RecordingSource.cloud);

      final me = MockProjectUser();
      when(() => me.userId).thenReturn('me');
      when(() => me.role).thenReturn(Viewer(userId: 'me'));

      final container = buildContainer(
        authState: AuthState(
          mode: AuthMode.authenticated,
          user: User(
            userId: 'me',
            name: 'Me',
            emailAddress: 'me@test.com',
            photoUrl: '',
          ),
        ),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.cloud('cp1', 'Cloud 1'),
          ],
          openProjectId: 'cp1',
          recordings: [r],
          projectUsers: [me],
          isRecordingSelectionMode: false,
          selectedRecordingIds: const {},
        ),
      );

      final controller = buildController(container);

      await controller.handleRecordingLongPress('r1');

      final state = container.read(homeStateProvider);
      expect(state.isRecordingSelectionMode, isFalse);
      expect(state.selectedRecordingIds, isEmpty);
    });

    test(
        'deleteRecordings local delete returns false -> selection cleared and refresh happens',
            () async {
          final rLocal = MockRecording();
          when(() => rLocal.id).thenReturn('r-local');
          when(() => rLocal.name).thenReturn('LocalRec');
          when(() => rLocal.isLocal).thenReturn(true);
          when(() => rLocal.source).thenReturn(RecordingSource.local);

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.local('p1', 'P1'),
              ],
              openProjectId: 'p1',
              recordings: [rLocal],
              isRecordingSelectionMode: true,
              selectedRecordingIds: {'r-local'},
            ),
          );
          final controller = buildController(container);

          when(
                () => recordingService.deleteLocalRecording(
              projectId: 'p1',
              recordingId: 'r-local',
            ),
          ).thenAnswer((_) async => false);

          when(() => recordingService.getLocalProjectRecordings('p1'))
              .thenAnswer((_) async => <Recording>[]);

          await controller.deleteRecordings({'r-local'});

          verify(() => recordingService.getLocalProjectRecordings('p1'))
              .called(greaterThanOrEqualTo(1));
          final state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test(
        'duplicateRecordings cloud returns empty -> marks failed and clears selection + refresh',
            () async {
          final rCloud = MockRecording();
          when(() => rCloud.id).thenReturn('r-cloud');
          when(() => rCloud.name).thenReturn('CloudRec');
          when(() => rCloud.isLocal).thenReturn(false);
          when(() => rCloud.source).thenReturn(RecordingSource.cloud);

          final container = buildContainer(
            authState: const AuthState(mode: AuthMode.guest),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
              openProjectId: 'cp1',
              recordings: [rCloud],
              isRecordingSelectionMode: true,
              selectedRecordingIds: {'r-cloud'},
            ),
          );
          final controller = buildController(container);

          when(
                () => recordingService.duplicateCloudRecordings(
              recordingIds: ['r-cloud'],
              projectId: 'cp1',
            ),
          ).thenAnswer((_) async => <Recording>[]);

          when(() => recordingService.getLocalProjectRecordings('cp1'))
              .thenAnswer((_) async => <Recording>[]);

          final proj = MockProject();
          when(() => proj.recordings).thenReturn(<Recording>[]);
          when(() => projectService.getProject('cp1')).thenAnswer((_) async => proj);

          await controller.duplicateRecordings({'r-cloud'});

          verify(() => recordingService.getLocalProjectRecordings('cp1'))
              .called(greaterThanOrEqualTo(1));
          final state = container.read(homeStateProvider);
          expect(state.selectedRecordingIds, isEmpty);
          expect(state.isRecordingSelectionMode, isFalse);
        });

    test('moveRecordings invalid target project id -> no calls', () async {
      final rLocal = MockRecording();
      when(() => rLocal.id).thenReturn('r1');
      when(() => rLocal.name).thenReturn('R1');
      when(() => rLocal.isLocal).thenReturn(true);
      when(() => rLocal.source).thenReturn(RecordingSource.local);

      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
          ],
          openProjectId: 'p1',
          recordings: [rLocal],
        ),
      );
      final controller = buildController(container);

      await controller.moveRecordings({'r1'}, targetProjectId: 'missing-target');

      verifyNever(
            () => projectService.moveRecordings(
          recordingIds: any(named: 'recordingIds'),
          targetProjectId: any(named: 'targetProjectId'),
        ),
      );
    });

    test('loadUsersForOpenProject default project -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          openProjectId: LocalMedia.defaultProjectId,
        ),
      );
      final controller = buildController(container);

      await controller.loadUsersForOpenProject(myUserId: 'me');

      verifyNever(() => projectService.getProjectUsers(any()));
    });

    test('loadUsersForOpenProject success -> sets users', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.authenticated),
        initialHomeState: HomeState.initial().copyWith(
          openProjectId: 'cp1',
        ),
      );
      final controller = buildController(container);

      final u = MockProjectUser();
      when(() => projectService.getProjectUsers('cp1'))
          .thenAnswer((_) async => <ProjectUser>[u]);

      await controller.loadUsersForOpenProject(myUserId: 'me');

      verify(() => projectService.getProjectUsers('cp1')).called(1);
      final state = container.read(homeStateProvider);
      expect(state.projectUsers.length, 1);
    });

    test('addUserToOpenProject default project -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          openProjectId: LocalMedia.defaultProjectId,
        ),
      );
      final controller = buildController(container);

      await controller.addUserToOpenProject(
        myUserId: 'me',
        emailAddress: 'a@b.com',
        role: ProjectRoleType.viewer,
      );

      verifyNever(
            () => projectService.addProjectUser(
          projectId: any(named: 'projectId'),
          emailAddress: any(named: 'emailAddress'),
          role: any(named: 'role'),
        ),
      );
    });

    test('addUserToOpenProject 409 -> no users set', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.authenticated),
        initialHomeState: HomeState.initial().copyWith(openProjectId: 'cp1'),
      );
      final controller = buildController(container);

      when(
            () => projectService.addProjectUser(
          projectId: 'cp1',
          emailAddress: 'a@b.com',
          role: ProjectRoleType.viewer,
        ),
      ).thenThrow(dioEx(409));

      await controller.addUserToOpenProject(
        myUserId: 'me',
        emailAddress: 'a@b.com',
        role: ProjectRoleType.viewer,
      );

      verify(
            () => projectService.addProjectUser(
          projectId: 'cp1',
          emailAddress: 'a@b.com',
          role: ProjectRoleType.viewer,
        ),
      ).called(1);
    });

    test('updateUserRoleForOpenProject myUserId null -> no calls', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.authenticated),
        initialHomeState: HomeState.initial().copyWith(openProjectId: 'cp1'),
      );
      final controller = buildController(container);

      await controller.updateUserRoleForOpenProject(
        myUserId: null,
        userId: 'u1',
        role: ProjectRoleType.editor,
      );

      verifyNever(
            () => projectService.updateProjectUserRole(
          projectId: any(named: 'projectId'),
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      );
    });

    test('removeUserFromOpenProject success -> calls remove + reload users', () async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.authenticated),
        initialHomeState: HomeState.initial().copyWith(openProjectId: 'cp1'),
      );
      final controller = buildController(container);

      when(
            () => projectService.removeUserFromProject(
          projectId: 'cp1',
          userId: 'u1',
        ),
      ).thenAnswer((_) async {});
      when(() => projectService.getProjectUsers('cp1'))
          .thenAnswer((_) async => <ProjectUser>[]);

      await controller.removeUserFromOpenProject(myUserId: 'me', userId: 'u1');

      verify(
            () => projectService.removeUserFromProject(
          projectId: 'cp1',
          userId: 'u1',
        ),
      ).called(1);
      verify(() => projectService.getProjectUsers('cp1')).called(1);
    });

    test(
        'handleGoToRecordingTap denied -> does not call callback (cloud project, authenticated, no role)',
            () async {
          var called = false;

          final container = buildContainer(
            authState: AuthState(
              mode: AuthMode.authenticated,
              user: User(
                userId: 'me',
                name: 'Me',
                emailAddress: 'me@test.com',
                photoUrl: '',
              ),
            ),
            initialHomeState: HomeState.initial().copyWith(
              projects: [
                ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
                ProjectMetadata.cloud('cp1', 'Cloud 1'),
              ],
              openProjectId: 'cp1',
            ),
          );
          final controller = buildController(container);

          when(() => projectService.getProjectUsers('cp1'))
              .thenAnswer((_) async => <ProjectUser>[]);

          await controller.handleGoToRecordingTap(goToRecording: () => called = true);

          expect(called, isFalse);
        });
  });
}