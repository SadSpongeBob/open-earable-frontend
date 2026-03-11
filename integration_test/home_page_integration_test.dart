import 'dart:io';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/project/project_user.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';

import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/features/home/widgets/project_grid.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Integration', () {
    late Directory tmp;

    setUpAll(() async {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://167.71.50.147:8080\n');
      tmp = await Directory.systemTemp.createTemp('openearable_integration');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('home page loads', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);
      final projectService = _FakeProjectService([
        ProjectMetadata.local('select1', 'Select Me'),
        ProjectMetadata.local('select2', 'Other'),
      ]);

      final recordingService = _FakeRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(
        userId: 'u1',
        name: 'Test User',
        emailAddress: 'test@example.com',
        photoUrl: null,
      ));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(RecordingGrid), findsOneWidget);
      expect(find.byType(ProjectBar), findsOneWidget);
    });

    testWidgets('projects are displayed', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final projectService = _FakeProjectService([
        ProjectMetadata.cloud('p3', 'Project A'),
        ProjectMetadata.cloud('p4', 'Project B'),
      ]);

      final recordingService = _FakeRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(
        userId: 'u1',
        name: 'Test User',
        emailAddress: 'test@example.com',
        photoUrl: null,
      ));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Project A'), findsOneWidget);
      expect(find.text('Project B'), findsOneWidget);
    });

    testWidgets('user can select a project', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final projectService = _FakeProjectService([
        ProjectMetadata.local('select1', 'Select Me'),
        ProjectMetadata.local('select2', 'Other'),
      ]);

      final recordingService = _FakeRecordingService({
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
      });

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(
        userId: 'u1',
        name: 'Test User',
        emailAddress: 'test@example.com',
        photoUrl: null,
      ));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();
      final textFinder = find.text('Select Me');
      expect(textFinder, findsOneWidget);
      final tileInkWell = find.ancestor(of: textFinder, matching: find.byType(InkWell));
      expect(tileInkWell, findsOneWidget);
      await tester.tap(tileInkWell);

      await tester.pumpAndSettle();
      expect(find.text('Recording A'), findsOneWidget);
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
  Future<void> renameProject(String projectId, String name) => throw UnimplementedError();
  @override
  Future<void> moveRecordings({required List<String> recordingIds, required String? targetProjectId}) => throw UnimplementedError();
  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();
  @override
  Future<ProjectMetadata> duplicateProject(String projectId) => throw UnimplementedError();
  @override
  Future<ProjectMetadata> createLocalProject({required String name, String? id}) => throw UnimplementedError();
  @override
  Future<void> deleteLocalProject(String projectId) => throw UnimplementedError();
  @override
  Future<void> duplicateLocalProject(String projectId, ProjectMetadata newProject) => throw UnimplementedError();
  @override
  Future<void> updateLocalProject({required ProjectMetadata project, String? oldProjectId}) => throw UnimplementedError();

  @override
  Future<List<ProjectUser>> addProjectUser({required String projectId, required String emailAddress, required ProjectRoleType role}) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getLocalProjectIds() => throw UnimplementedError();

  @override
  Future<List<ProjectUser>> getProjectUsers(String projectId) => throw UnimplementedError();

  @override
  Future<void> leaveProject({required String projectId}) => throw UnimplementedError();

  @override
  Future<void> overwriteMetaIfProjectDirExists(String projectId, ProjectMetadata project) => throw UnimplementedError();

  @override
  Future<void> removeUserFromProject({required String projectId, required String userId}) => throw UnimplementedError();

  @override
  Future<void> updateProjectUserRole({required String projectId, required String userId, required ProjectRoleType role}) => throw UnimplementedError();
}

class _FakeRecordingService implements RecordingService {
  final Map<String, List<Recording>> _localRecordings;

  _FakeRecordingService([Map<String, List<Recording>> initialRecordings = const {}])
      : _localRecordings = Map.from(initialRecordings);

  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async =>
      List.of(_localRecordings[projectId] ?? []);

  @override
  Future<Recording> completeUpload(String recordingId) => throw UnimplementedError();
  @override
  Future<GetRecordingResponse> getRecording(String recordingId) => throw UnimplementedError();
  @override
  Future<List<Recording>> getRecordings() => throw UnimplementedError();
  @override
  Future<void> renameCloud({required String recordingId, required String name}) => throw UnimplementedError();
  @override
  Future<void> deleteCloudRecording(String recordingId) => throw UnimplementedError();
  @override
  Future<List<Recording>> duplicateCloudRecordings({required List<String> recordingIds, String? projectId}) => throw UnimplementedError();
  @override
  Future<Recording> getLocalRecording(String projectId, String recordingId) => throw UnimplementedError();
  @override
  Future<List<Recording>> getLocalRecordings() => throw UnimplementedError();
  @override
  Future<List<Sensor>> getLocalRecordingSensors(String projectId, String recordingId) => throw UnimplementedError();
  @override
  Future<bool> deleteLocalRecording({required String projectId, required String recordingId}) => throw UnimplementedError();
  @override
  Future<void> renameLocal({required String projectId, required String recordingId, required String newName}) => throw UnimplementedError();

  @override
  Future<bool> duplicateLocalRecording({required String projectId, required String sourceRecordingId, required String newRecordingId, required String newName}) => throw UnimplementedError();

  @override
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) => throw UnimplementedError();

  @override
  Future<void> updateLocalUploadStatus(String projectId, String recordingId, UploadStatus uploadStatus) => throw UnimplementedError();

}
