import 'dart:io';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/project/project_user.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';
import 'package:openearable/features/home/widgets/recording_action_bar.dart';
import 'package:openearable/features/home/widgets/move_recordings_modal.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Integration - Recording Management', () {
    late Directory tmp;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('openearable_recording_tests');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('recordings are displayed for the open project', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      // seed one cloud project with one recording
      final recordings = [
        Recording(
          id: 'r1',
          name: 'Rec 1',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'proj1',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({
        'proj1': Project(id: 'proj1', name: 'Project Rec', ownerId: 'u1', recordings: recordings, users: []),
      });

      final recordingService = _RecordingTestRecordingService(projectRecordings: {'proj1': List.of(recordings)});

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));

      await tester.pumpAndSettle();

      expect(find.text('Rec 1'), findsOneWidget);
      expect(find.byType(RecordingGrid), findsOneWidget);
    });

    testWidgets('user can enter recording selection mode by long pressing a recording', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final recordings = [
        Recording(
          id: 'r2',
          name: 'Rec Select',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'proj2',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({'proj2': Project(id: 'proj2', name: 'Project S', ownerId: 'u1', recordings: recordings, users: [])});
      final recordingService = _RecordingTestRecordingService(projectRecordings: {'proj2': List.of(recordings)});

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();

      final tile = find.text('Rec Select');
      expect(tile, findsOneWidget);

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      expect(find.byType(RecordingSelectionActionBar), findsOneWidget);
    });

    testWidgets('user can delete a selected recording', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final recordings = [
        Recording(
          id: 'r3',
          name: 'Rec Delete',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'proj3',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({'proj3': Project(id: 'proj3', name: 'Project D', ownerId: 'u1', recordings: List.of(recordings), users: [])});
      final recordingService = _RecordingTestRecordingService(projectRecordings: {'proj3': List.of(recordings)}, projectService: projectService);

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();

      final tile = find.text('Rec Delete');
      expect(tile, findsOneWidget);

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(TextButton, 'Delete').first;
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('This action cannot be undone'), findsOneWidget);

      // Tap the Delete button in dialog (AppButton.dangerGhost)
      final confirmDelete = find.text('Delete').last; // last should be dialog button
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      final remaining = await projectService.getProject('proj3');
      expect(remaining.recordings.where((r) => r.id == 'r3').isEmpty, isTrue);

      // Selection mode should be cleared (action bar gone)
      expect(find.byType(RecordingSelectionActionBar), findsNothing);
    });

    testWidgets('user can duplicate a selected recording', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final recordings = [
        Recording(
          id: 'r4',
          name: 'Rec Dup',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'proj4',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({'proj4': Project(id: 'proj4', name: 'Project Dup', ownerId: 'u1', recordings: List.of(recordings), users: [])});
      final recordingService = _RecordingTestRecordingService(projectRecordings: {'proj4': List.of(recordings)}, projectService: projectService);

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();

      final tile = find.text('Rec Dup');
      expect(tile, findsOneWidget);

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      final dupButton = find.widgetWithText(TextButton, 'Duplicate').first;
      expect(dupButton, findsOneWidget);
      await tester.tap(dupButton);
      await tester.pumpAndSettle();

      final proj = await projectService.getProject('proj4');
      expect(proj.recordings.length, greaterThan(1));

      expect(find.byType(RecordingSelectionActionBar), findsNothing);
    });

    testWidgets('user can start move mode and pick a target project', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      // Source project with one cloud recording
      final recordings = [
        Recording(
          id: 'r5',
          name: 'Rec Move',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'src',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({
        'src': Project(id: 'src', name: 'Source', ownerId: 'u1', recordings: List.of(recordings), users: []),
        'tgt': Project(id: 'tgt', name: 'Target', ownerId: 'u1', recordings: [], users: []),
      });

      final recordingService = _RecordingTestRecordingService(projectRecordings: {'src': List.of(recordings)}, projectService: projectService);

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();

      final tile = find.text('Rec Move');
      expect(tile, findsOneWidget);
      await tester.longPress(tile);
      await tester.pumpAndSettle();

      final moveButton = find.widgetWithText(TextButton, 'Move').first;
      expect(moveButton, findsOneWidget);
      await tester.tap(moveButton);
      await tester.pumpAndSettle();

      expect(find.byType(MoveRecordingsModal), findsOneWidget);

      final targetTile = find.text('Target');
      expect(targetTile, findsOneWidget);
      await tester.tap(targetTile);
      await tester.pumpAndSettle();

      final tgtProj = await projectService.getProject('tgt');
      expect(tgtProj.recordings.any((r) => r.id == 'r5'), isTrue);
      expect(find.byType(RecordingSelectionActionBar), findsNothing);
    });

    testWidgets('user can exit recording selection mode with done', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final recordings = [
        Recording(
          id: 'r6',
          name: 'Rec Done',
          source: RecordingSource.cloud,
          thumbnailUrl: null,
          localThumbnailPath: null,
          localVideoPath: null,
          videoTimestamp: DateTime.now().toUtc(),
          projectId: 'proj6',
          userId: 'u1',
          uploadStatus: UploadStatus.completed,
        ),
      ];

      final projectService = _RecordingTestProjectService({'proj6': Project(id: 'proj6', name: 'Project Done', ownerId: 'u1', recordings: List.of(recordings), users: [])});
      final recordingService = _RecordingTestRecordingService(projectRecordings: {'proj6': List.of(recordings)}, projectService: projectService);

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'User', emailAddress: 'u@example.com', photoUrl: null));

      final homeStateNotifier = HomeStateNotifier();

      final overrides = <Override>[
        localMediaProvider.overrideWithValue(localMedia),
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        sessionProvider.overrideWith((ref) => authNotifier),
        homeStateProvider.overrideWith((ref) => homeStateNotifier),
      ];

      await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: HomePage())));
      await tester.pumpAndSettle();

      final tile = find.text('Rec Done');
      expect(tile, findsOneWidget);

      await tester.longPress(tile);
      await tester.pumpAndSettle();

      final doneButton = find.widgetWithText(TextButton, 'Done').first;
      expect(doneButton, findsOneWidget);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.byType(RecordingSelectionActionBar), findsNothing);
    });
  });
}

// ---------------------
// Fake service helpers
// ---------------------

class _RecordingTestProjectService implements ProjectService {
  final Map<String, Project> _projects;

  _RecordingTestProjectService(Map<String, Project> projects) : _projects = Map.of(projects);

  @override
  Future<Project> getProject(String projectId) async {
    final p = _projects[projectId];
    if (p == null) throw StateError('Project not found: $projectId');
    return p;
  }

  @override
  Future<List<ProjectMetadata>> getProjects() async {
    return _projects.values
        .map((p) => ProjectMetadata.cloud(p.id, p.name))
        .toList();
  }

  @override
  Future<List<ProjectMetadata>> getLocalProjects() async => [];

  @override
  Future<void> moveRecordings({required List<String> recordingIds, required String? targetProjectId}) async {
    if (targetProjectId == null) return;
    for (final pid in _projects.keys) {
      final p = _projects[pid]!;
      final moving = p.recordings.where((r) => recordingIds.contains(r.id)).toList();
      if (moving.isEmpty) continue;
      _projects[pid] = Project(id: p.id, name: p.name, ownerId: p.ownerId, recordings: p.recordings.where((r) => !recordingIds.contains(r.id)).toList(), users: p.users);
      final target = _projects[targetProjectId]!;
      _projects[targetProjectId] = Project(id: target.id, name: target.name, ownerId: target.ownerId, recordings: [...target.recordings, ...moving], users: target.users);
    }
  }

  @override
  Future<Project> createProject(String name) => throw UnimplementedError();
  @override
  Future<void> renameProject(String projectId, String name) => throw UnimplementedError();
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
  Future<List<ProjectUser>> addProjectUser({required String projectId, required String emailAddress, required ProjectRoleType role}) => throw UnimplementedError();
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

class _RecordingTestRecordingService implements RecordingService {
  final Map<String, List<Recording>> projectRecordings;
  final _RecordingTestProjectService? projectService;

  _RecordingTestRecordingService({required this.projectRecordings, this.projectService});

  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    return List.of(projectRecordings[projectId] ?? []);
  }

  @override
  Future<void> deleteCloudRecording(String recordingId) async {
    for (final key in projectRecordings.keys) {
      projectRecordings[key] = projectRecordings[key]!.where((r) => r.id != recordingId).toList();
      projectService?._projects.update(key, (p) => Project(id: p.id, name: p.name, ownerId: p.ownerId, recordings: projectRecordings[key]!, users: p.users));
    }
  }

  @override
  Future<List<Recording>> duplicateCloudRecordings({required List<String> recordingIds, String? projectId}) async {
    final dst = projectId ?? projectRecordings.keys.first;
    final list = projectRecordings[dst]!;
    final added = <Recording>[];
    for (final id in recordingIds) {
      final original = list.firstWhere((r) => r.id == id, orElse: () => throw StateError('recording not found'));
      final newId = '${id}_copy';
      final newRec = Recording(
        id: newId,
        name: '${original.name} (Copy)',
        source: original.source,
        thumbnailUrl: original.thumbnailUrl,
        localThumbnailPath: original.localThumbnailPath,
        localVideoPath: original.localVideoPath,
        videoTimestamp: DateTime.now().toUtc(),
        projectId: original.projectId,
        userId: original.userId,
        uploadStatus: original.uploadStatus,
      );
      projectRecordings[dst] = [...projectRecordings[dst]!, newRec];
      // sync projectService
      projectService?._projects.update(dst, (p) => Project(id: p.id, name: p.name, ownerId: p.ownerId, recordings: projectRecordings[dst]!, users: p.users));
      added.add(newRec);
    }
    return added;
  }

  // Stubs for interface
  @override
  Future<Recording> completeUpload(String recordingId) => throw UnimplementedError();
  @override
  Future<GetRecordingResponse> getRecording(String recordingId) => throw UnimplementedError();
  @override
  Future<List<Recording>> getRecordings() => throw UnimplementedError();
  @override
  Future<void> renameCloud({required String recordingId, required String name}) => throw UnimplementedError();
  @override
  Future<bool> deleteLocalRecording({required String projectId, required String recordingId}) => throw UnimplementedError();
  @override
  Future<Recording> getLocalRecording(String projectId, String recordingId) => throw UnimplementedError();
  @override
  Future<List<Recording>> getLocalRecordings() => throw UnimplementedError();
  @override
  Future<List<Sensor>> getLocalRecordingSensors(String projectId, String recordingId) => throw UnimplementedError();
  @override
  Future<void> renameLocal({required String projectId, required String recordingId, required String newName}) => throw UnimplementedError();
  @override
  Future<bool> duplicateLocalRecording({required String projectId, required String sourceRecordingId, required String newRecordingId, required String newName}) => throw UnimplementedError();
  @override
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) => throw UnimplementedError();
  @override
  Future<void> updateLocalUploadStatus(String projectId, String recordingId, UploadStatus uploadStatus) => throw UnimplementedError();
}
