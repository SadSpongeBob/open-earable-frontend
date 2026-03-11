import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/project/project_user.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/widgets/project_grid.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';

class _SettingsStub extends StatelessWidget {
  const _SettingsStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('SettingsPage')));
}

class _SensorStub extends StatelessWidget {
  const _SensorStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('SensorPage')));
}

class _RecordingStub extends StatelessWidget {
  const _RecordingStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('RecordingPage')));
}

Future<void> _disposeHome(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _pumpHome(
    WidgetTester tester, {
      required Directory tmp,
      required ProjectService projectService,
      required RecordingService recordingService,
      HomeStateNotifier? homeStateNotifier,
    }) async {
  final localMedia = LocalMedia(tmp, tmp, tmp);
  final authNotifier = SessionNotifier();
  authNotifier.setAuthenticated(
    User(
      userId: 'u1',
      name: 'Test User',
      emailAddress: 'test@example.com',
      photoUrl: null,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith(
              (ref) => homeStateNotifier ?? HomeStateNotifier(),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpRouterHome(
    WidgetTester tester, {
      required Directory tmp,
      required ProjectService projectService,
      required RecordingService recordingService,
    }) async {
  final localMedia = LocalMedia(tmp, tmp, tmp);
  final authNotifier = SessionNotifier();
  authNotifier.setAuthenticated(
    User(
      userId: 'u1',
      name: 'Test User',
      emailAddress: 'test@example.com',
      photoUrl: null,
    ),
  );

  final overrides = <Override>[
    localMediaProvider.overrideWithValue(localMedia),
    projectServiceProvider.overrideWithValue(projectService),
    recordingServiceProvider.overrideWithValue(recordingService),
    sessionProvider.overrideWith((ref) => authNotifier),
    homeStateProvider.overrideWith((ref) => HomeStateNotifier()),
  ];

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => ProviderScope(
          overrides: overrides,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (c, s) => const _SettingsStub(),
      ),
      GoRoute(
        path: '/sensordata',
        builder: (c, s) => const _SensorStub(),
      ),
      GoRoute(
        path: '/recording',
        builder: (c, s) => const _RecordingStub(),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Integration', () {
    late Directory tmp;

    setUpAll(() async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://167.71.50.147:8080\n');
      tmp = await Directory.systemTemp.createTemp('openearable_integration');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('home page loads', (tester) async {
      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: _FakeProjectService([
          ProjectMetadata.local('select1', 'Select Me'),
          ProjectMetadata.local('select2', 'Other'),
        ]),
        recordingService: _FakeRecordingService(),
      );

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(RecordingGrid), findsOneWidget);
      expect(find.byType(ProjectBar), findsOneWidget);

      await _disposeHome(tester);
    });

    testWidgets('projects are displayed', (tester) async {
      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: _FakeProjectService([
          ProjectMetadata.cloud('p3', 'Project A'),
          ProjectMetadata.cloud('p4', 'Project B'),
        ]),
        recordingService: _FakeRecordingService(),
      );

      expect(find.text('Project A'), findsOneWidget);
      expect(find.text('Project B'), findsOneWidget);

      await _disposeHome(tester);
    });

    testWidgets('user can select a project', (tester) async {
      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: _FakeProjectService([
          ProjectMetadata.local('select1', 'Select Me'),
          ProjectMetadata.local('select2', 'Other'),
        ]),
        recordingService: _FakeRecordingService({
          'select1': [
            Recording.local(
              id: 'r1',
              name: 'Recording A',
              localVideoPath: '${tmp.path}/r1.mp4',
              videoTimestamp: DateTime.now(),
              projectId: 'select1',
            ),
          ],
          'select2': [
            Recording.local(
              id: 'r2',
              name: 'Recording B',
              localVideoPath: '${tmp.path}/r2.mp4',
              videoTimestamp: DateTime.now(),
              projectId: 'select2',
            ),
          ],
        }),
      );

      final textFinder = find.text('Select Me');
      expect(textFinder, findsOneWidget);
      final tileInkWell = find.ancestor(
        of: textFinder,
        matching: find.byType(InkWell),
      );
      expect(tileInkWell, findsOneWidget);

      await tester.tap(tileInkWell);
      await tester.pumpAndSettle();

      expect(find.text('Recording A'), findsOneWidget);

      await _disposeHome(tester);
    });

    group('Project Management', () {
      testWidgets('add project', (tester) async {
        final projectService = _MutableFakeProjectService([
          ProjectMetadata.local('p1', 'Project One'),
        ]);

        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: projectService,
          recordingService: _FakeRecordingService(),
        );

        final before = (await projectService.getLocalProjects()).length;

        final addImage = find.byWidgetPredicate((w) {
          if (w is Image && w.image is AssetImage) {
            return (w.image as AssetImage).assetName.contains('add_folder');
          }
          return false;
        });
        expect(addImage, findsOneWidget);

        final addTapTarget = find.ancestor(
          of: addImage,
          matching: find.byType(InkWell),
        );
        expect(addTapTarget, findsOneWidget);

        await tester.tap(addTapTarget);
        await tester.pumpAndSettle();

        expect(find.text('Add Project'), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, 'New Project');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add').last);
        await tester.pumpAndSettle();

        final after = (await projectService.getLocalProjects()).length;
        expect(after, before + 1);
        expect(find.text('New Project'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('enter project selection mode with long press', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _MutableFakeProjectService([
            ProjectMetadata.local('p1', 'Project One'),
            ProjectMetadata.local('p2', 'Project Two'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final projectTile = find.text('Project One');
        expect(projectTile, findsOneWidget);

        await tester.longPress(projectTile);
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('exit project selection mode with done', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _MutableFakeProjectService([
            ProjectMetadata.local('p1', 'Project One'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        await tester.longPress(find.text('Project One'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsNothing);

        await _disposeHome(tester);
      });

      testWidgets('duplicate selected project', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _MutableFakeProjectService([
            ProjectMetadata.local('p1', 'Project One'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        await tester.longPress(find.text('Project One'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Duplicate'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Copy'), findsWidgets);

        await _disposeHome(tester);
      });

      testWidgets('rename selected project', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _MutableFakeProjectService([
            ProjectMetadata.local('p1', 'Project One'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        await tester.longPress(find.text('Project One'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Renamed');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ok'));
        await tester.pumpAndSettle();

        expect(find.text('Renamed'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('delete selected project', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _MutableFakeProjectService([
            ProjectMetadata.local('p1', 'Project One'),
            ProjectMetadata.local('p2', 'Project Two'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        await tester.longPress(find.text('Project One'));
        await tester.pumpAndSettle();

        final deleteButtons = find.text('Delete');
        expect(deleteButtons, findsWidgets);

        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(find.text('Project One'), findsNothing);

        await _disposeHome(tester);
      });
    });

    group('Navigation / Right Bar', () {
      testWidgets('tap settings button navigates to settings', (tester) async {
        await _pumpRouterHome(
          tester,
          tmp: tmp,
          projectService: _FakeProjectService([
            ProjectMetadata.local('p1', 'Project A'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final settingsBtn = find.bySemanticsLabel('Settings');
        expect(settingsBtn, findsOneWidget);

        await tester.tap(settingsBtn);
        await tester.pumpAndSettle();

        expect(find.text('SettingsPage'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('tap sensor/wavesound button navigates to sensor page', (tester) async {
        await _pumpRouterHome(
          tester,
          tmp: tmp,
          projectService: _FakeProjectService([
            ProjectMetadata.local('p1', 'Project A'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final sensorBtn = find.bySemanticsLabel('Show sensor chart overlay');
        expect(sensorBtn, findsOneWidget);

        await tester.tap(sensorBtn);
        await tester.pumpAndSettle();

        expect(find.text('SensorPage'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('tap shutter button navigates to recording page', (tester) async {
        await _pumpRouterHome(
          tester,
          tmp: tmp,
          projectService: _FakeProjectService([
            ProjectMetadata.local('p1', 'Project A'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final recordingBtn = find.bySemanticsLabel('Record');
        expect(recordingBtn, findsOneWidget);

        await tester.tap(recordingBtn);
        await tester.pumpAndSettle();

        expect(find.text('RecordingPage'), findsOneWidget);

        await _disposeHome(tester);
      });
    });

    group('Bluetooth Popup', () {
      testWidgets('bluetooth popup opens', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _FakeProjectService([
            ProjectMetadata.local('p1', 'Project A'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final btBtn = find.bySemanticsLabel('Connect Bluetooth device');
        expect(btBtn, findsOneWidget);

        await tester.tap(btBtn);
        await tester.pumpAndSettle();

        expect(find.text('Devices'), findsOneWidget);

        await _disposeHome(tester);
      });

      testWidgets('bluetooth popup closes', (tester) async {
        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: _FakeProjectService([
            ProjectMetadata.local('p1', 'Project A'),
          ]),
          recordingService: _FakeRecordingService(),
        );

        final btBtn = find.bySemanticsLabel('Connect Bluetooth device');
        expect(btBtn, findsOneWidget);

        await tester.tap(btBtn);
        await tester.pumpAndSettle();

        expect(find.text('Devices'), findsOneWidget);

        await tester.tapAt(const Offset(0, 0));
        await tester.pumpAndSettle();

        expect(find.text('Devices'), findsNothing);

        await _disposeHome(tester);
      });
    });
  });
}

class _FakeProjectService implements ProjectService {
  final List<ProjectMetadata> _projects;

  _FakeProjectService(this._projects);

  @override
  Future<List<ProjectMetadata>> getProjects() async =>
      _projects.where((p) => p.projectSource == ProjectSource.cloud).toList();

  @override
  Future<List<ProjectMetadata>> getLocalProjects() async =>
      _projects.where((p) => p.projectSource == ProjectSource.local).toList();

  @override
  Future<Project> getProject(String projectId) async {
    final meta = _projects.firstWhere((p) => p.id == projectId, orElse: () {
      throw Exception('Project not found: $projectId');
    });

    return Project(
      id: meta.id,
      name: meta.name,
      ownerId: 'u1',
      recordings: const [],
      users: const [],
    );
  }

  @override
  Future<Project> createProject(String name) => throw UnimplementedError();

  @override
  Future<void> renameProject(String projectId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> moveRecordings({
    required List<String> recordingIds,
    required String? targetProjectId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();

  @override
  Future<ProjectMetadata> duplicateProject(String projectId) =>
      throw UnimplementedError();

  @override
  Future<ProjectMetadata> createLocalProject({required String name, String? id}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteLocalProject(String projectId) =>
      throw UnimplementedError();

  @override
  Future<void> duplicateLocalProject(
      String projectId,
      ProjectMetadata newProject,
      ) => throw UnimplementedError();

  @override
  Future<void> updateLocalProject({
    required ProjectMetadata project,
    String? oldProjectId,
  }) => throw UnimplementedError();

  @override
  Future<List<ProjectUser>> addProjectUser({
    required String projectId,
    required String emailAddress,
    required ProjectRoleType role,
  }) => throw UnimplementedError();

  @override
  Future<List<String>> getLocalProjectIds() => throw UnimplementedError();

  @override
  Future<List<ProjectUser>> getProjectUsers(String projectId) =>
      throw UnimplementedError();

  @override
  Future<void> leaveProject({required String projectId}) =>
      throw UnimplementedError();

  @override
  Future<void> overwriteMetaIfProjectDirExists(
      String projectId,
      ProjectMetadata project,
      ) => throw UnimplementedError();

  @override
  Future<void> removeUserFromProject({
    required String projectId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> updateProjectUserRole({
    required String projectId,
    required String userId,
    required ProjectRoleType role,
  }) => throw UnimplementedError();
}

class _FakeRecordingService implements RecordingService {
  final Map<String, List<Recording>> _localRecordings;

  _FakeRecordingService([Map<String, List<Recording>> initialRecordings = const {}])
      : _localRecordings = Map.from(initialRecordings);

  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async =>
      List.of(_localRecordings[projectId] ?? []);

  @override
  Future<Recording> completeUpload(String recordingId) =>
      throw UnimplementedError();

  @override
  Future<GetRecordingResponse> getRecording(String recordingId) =>
      throw UnimplementedError();

  @override
  Future<List<Recording>> getRecordings() => throw UnimplementedError();

  @override
  Future<void> renameCloud({
    required String recordingId,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCloudRecording(String recordingId) =>
      throw UnimplementedError();

  @override
  Future<List<Recording>> duplicateCloudRecordings({
    required List<String> recordingIds,
    String? projectId,
  }) => throw UnimplementedError();

  @override
  Future<Recording> getLocalRecording(String projectId, String recordingId) =>
      throw UnimplementedError();

  @override
  Future<List<Recording>> getLocalRecordings() =>
      throw UnimplementedError();

  @override
  Future<List<Sensor>> getLocalRecordingSensors(
      String projectId,
      String recordingId,
      ) => throw UnimplementedError();

  @override
  Future<bool> deleteLocalRecording({
    required String projectId,
    required String recordingId,
  }) => throw UnimplementedError();

  @override
  Future<void> renameLocal({
    required String projectId,
    required String recordingId,
    required String newName,
  }) => throw UnimplementedError();

  @override
  Future<bool> duplicateLocalRecording({
    required String projectId,
    required String sourceRecordingId,
    required String newRecordingId,
    required String newName,
  }) => throw UnimplementedError();

  @override
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) =>
      throw UnimplementedError();

  @override
  Future<void> updateLocalUploadStatus(
      String projectId,
      String recordingId,
      UploadStatus uploadStatus,
      ) => throw UnimplementedError();
}

class _MutableFakeProjectService extends _FakeProjectService {
  _MutableFakeProjectService(super.projects);

  @override
  Future<Project> createProject(String name) async {
    final newId = 'p${_projects.length + 1}';
    final meta = ProjectMetadata.local(newId, name);
    _projects.add(meta);
    return Project(
      id: newId,
      name: name,
      ownerId: 'u1',
      recordings: const [],
      users: const [],
    );
  }

  @override
  Future<ProjectMetadata> createLocalProject({required String name, String? id}) async {
    final newId = id ?? 'p${_projects.length + 1}';
    final meta = ProjectMetadata.local(newId, name);
    _projects.add(meta);
    return meta;
  }

  @override
  Future<void> updateLocalProject({required ProjectMetadata project, String? oldProjectId}) async {
    final index = _projects.indexWhere((p) => p.id == (oldProjectId ?? project.id));
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
  }

  @override
  Future<void> deleteLocalProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
  }

  @override
  Future<void> duplicateLocalProject(String projectId, ProjectMetadata newProject) async {
    _projects.add(newProject);
  }
}