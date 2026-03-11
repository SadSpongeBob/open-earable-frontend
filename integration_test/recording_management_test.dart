import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:openearable/features/home/widgets/move_recordings_modal.dart';
import 'package:openearable/features/home/widgets/recording_action_bar.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
}

Future<void> _disposeHome(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.binding.setSurfaceSize(null);
}

Future<void> _pumpHome(
    WidgetTester tester, {
      required Directory tmp,
      required ProjectService projectService,
      required RecordingService recordingService,
      HomeStateNotifier? homeStateNotifier,
    }) async {
  await _setLargeSurface(tester);

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

Future<void> _openProject(WidgetTester tester, String name) async {
  final projectFinder = find.text(name);
  expect(projectFinder, findsOneWidget);
  await tester.tap(projectFinder);
  await tester.pumpAndSettle();
}

Finder _recordingTextInGrid(String text) {
  return find.descendant(
    of: find.byType(RecordingGrid),
    matching: find.text(text),
  ).first;
}

ProjectRole _ownerUser() {
  return Owner(userId: 'u1');
}

Recording _cloudRecording({
  required String id,
  required String name,
  required String projectId,
}) {
  return Recording(
    id: id,
    name: name,
    source: RecordingSource.cloud,
    thumbnailUrl: null,
    localThumbnailPath: null,
    localVideoPath: null,
    videoTimestamp: DateTime.now().toUtc(),
    projectId: projectId,
    userId: 'u1',
    uploadStatus: UploadStatus.completed,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Integration - Recording Management', () {
    late Directory tmp;

    setUpAll(() async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://167.71.50.147:8080\n');
      tmp = await Directory.systemTemp.createTemp('openearable_recording_tests');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('recordings are displayed for the open project', (tester) async {
      final ownerUser = _ownerUser();
      final recordings = [
        _cloudRecording(id: 'r1', name: 'Rec 1', projectId: 'proj1'),
      ];

      final projectService = _RecordingTestProjectService({
        'proj1': Project(
          id: 'proj1',
          name: 'Project Rec',
          ownerId: 'u1',
          recordings: recordings,
          users: [ownerUser],
        ),
      });

      final recordingService = _RecordingTestRecordingService(
        projectRecordings: {'proj1': List.of(recordings)},
        projectService: projectService,
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Rec');

      expect(_recordingTextInGrid('Rec 1'), findsOneWidget);
      expect(find.byType(RecordingGrid), findsOneWidget);

      await _disposeHome(tester);
    });

    testWidgets(
      'user can enter recording selection mode by long pressing a recording',
          (tester) async {
        final ownerUser = _ownerUser();
        final recordings = [
          _cloudRecording(id: 'r2', name: 'Rec Select', projectId: 'proj2'),
        ];

        final projectService = _RecordingTestProjectService({
          'proj2': Project(
            id: 'proj2',
            name: 'Project S',
            ownerId: 'u1',
            recordings: recordings,
            users: [ownerUser],
          ),
        });

        final recordingService = _RecordingTestRecordingService(
          projectRecordings: {'proj2': List.of(recordings)},
          projectService: projectService,
        );

        await _pumpHome(
          tester,
          tmp: tmp,
          projectService: projectService,
          recordingService: recordingService,
        );

        await _openProject(tester, 'Project S');

        await tester.longPress(_recordingTextInGrid('Rec Select'));
        await tester.pumpAndSettle();

        expect(find.byType(RecordingSelectionActionBar), findsOneWidget);

        await _disposeHome(tester);
      },
    );

    testWidgets('user can delete a selected recording', (tester) async {
      final ownerUser = _ownerUser();
      final recordings = [
        _cloudRecording(id: 'r3', name: 'Rec Delete', projectId: 'proj3'),
      ];

      final projectService = _RecordingTestProjectService({
        'proj3': Project(
          id: 'proj3',
          name: 'Project D',
          ownerId: 'u1',
          recordings: List.of(recordings),
          users: [ownerUser],
        ),
      });

      final recordingService = _RecordingTestRecordingService(
        projectRecordings: {'proj3': List.of(recordings)},
        projectService: projectService,
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project D');

      await tester.longPress(_recordingTextInGrid('Rec Delete'));
      await tester.pumpAndSettle();

      final deleteButtons = find.text('Delete');
      expect(deleteButtons, findsWidgets);

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      final confirmDeleteFinder = find.text('Delete');
      expect(confirmDeleteFinder, findsWidgets);
      await tester.tap(confirmDeleteFinder.last);
      await tester.pumpAndSettle();

      final remaining = await projectService.getProject('proj3');
      expect(remaining.recordings.where((r) => r.id == 'r3').isEmpty, isTrue);
      expect(find.byType(RecordingSelectionActionBar), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RecordingGrid),
          matching: find.text('Rec Delete'),
        ),
        findsNothing,
      );

      await _disposeHome(tester);
    });

    testWidgets('user can duplicate a selected recording', (tester) async {
      final ownerUser = _ownerUser();
      final recordings = [
        _cloudRecording(id: 'r4', name: 'Rec Dup', projectId: 'proj4'),
      ];

      final projectService = _RecordingTestProjectService({
        'proj4': Project(
          id: 'proj4',
          name: 'Project Dup',
          ownerId: 'u1',
          recordings: List.of(recordings),
          users: [ownerUser],
        ),
      });

      final recordingService = _RecordingTestRecordingService(
        projectRecordings: {'proj4': List.of(recordings)},
        projectService: projectService,
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Dup');

      await tester.longPress(_recordingTextInGrid('Rec Dup'));
      await tester.pumpAndSettle();

      final duplicateFinder = find.text('Duplicate');
      expect(duplicateFinder, findsWidgets);
      await tester.tap(duplicateFinder.first);
      await tester.pumpAndSettle();

      final proj = await projectService.getProject('proj4');
      expect(proj.recordings.length, greaterThan(1));
      expect(find.textContaining('Copy'), findsWidgets);
      expect(find.byType(RecordingSelectionActionBar), findsNothing);

      await _disposeHome(tester);
    });

    testWidgets('user can start move mode and pick a target project', (
        tester,
        ) async {
      final ownerUser = _ownerUser();
      final recordings = [
        _cloudRecording(id: 'r5', name: 'Rec Move', projectId: 'src'),
      ];

      final projectService = _RecordingTestProjectService({
        'src': Project(
          id: 'src',
          name: 'Source',
          ownerId: 'u1',
          recordings: List.of(recordings),
          users: [ownerUser],
        ),
        'tgt': Project(
          id: 'tgt',
          name: 'Target',
          ownerId: 'u1',
          recordings: const [],
          users: [ownerUser],
        ),
      });

      final recordingService = _RecordingTestRecordingService(
        projectRecordings: {'src': List.of(recordings), 'tgt': const []},
        projectService: projectService,
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Source');

      await tester.longPress(_recordingTextInGrid('Rec Move'));
      await tester.pumpAndSettle();

      final moveFinder = find.text('Move');
      expect(moveFinder, findsWidgets);
      await tester.tap(moveFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(MoveRecordingsModal), findsOneWidget);

      final targetFinder = find.text('Target');
      expect(targetFinder, findsOneWidget);
      await tester.tap(targetFinder);
      await tester.pumpAndSettle();

      final srcProj = await projectService.getProject('src');
      final tgtProj = await projectService.getProject('tgt');

      expect(srcProj.recordings.any((r) => r.id == 'r5'), isFalse);
      expect(tgtProj.recordings.any((r) => r.id == 'r5'), isTrue);
      expect(find.byType(RecordingSelectionActionBar), findsNothing);

      await _disposeHome(tester);
    });

    testWidgets('user can exit recording selection mode with done', (
        tester,
        ) async {
      final ownerUser = _ownerUser();
      final recordings = [
        _cloudRecording(id: 'r6', name: 'Rec Done', projectId: 'proj6'),
      ];

      final projectService = _RecordingTestProjectService({
        'proj6': Project(
          id: 'proj6',
          name: 'Project Done',
          ownerId: 'u1',
          recordings: List.of(recordings),
          users: [ownerUser],
        ),
      });

      final recordingService = _RecordingTestRecordingService(
        projectRecordings: {'proj6': List.of(recordings)},
        projectService: projectService,
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Done');

      await tester.longPress(_recordingTextInGrid('Rec Done'));
      await tester.pumpAndSettle();

      final doneFinder = find.text('Done');
      expect(doneFinder, findsOneWidget);
      await tester.tap(doneFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RecordingSelectionActionBar), findsNothing);

      await _disposeHome(tester);
    });
  });
}

class _RecordingTestProjectService implements ProjectService {
  final Map<String, Project> _projects;
  void Function(String projectId, List<Recording> recordings)?
  projectRecordingsSync;

  _RecordingTestProjectService(Map<String, Project> projects)
      : _projects = Map.of(projects);

  @override
  Future<Project> getProject(String projectId) async {
    final p = _projects[projectId];
    if (p == null) {
      throw StateError('Project not found: $projectId');
    }
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
  Future<List<ProjectUser>> getProjectUsers(String projectId) async {
    final p = _projects[projectId];
    if (p == null) {
      throw StateError('Project not found: $projectId');
    }

    return p.users.map((role) {
      return ProjectUser(
        userId: role.userId,
        name: role.userId,
        emailAddress: '${role.userId}@example.com',
        pictureUrl: null,
        role: role,
      );
    }).toList();
  }

  @override
  Future<void> moveRecordings({
    required List<String> recordingIds,
    required String? targetProjectId,
  }) async {
    if (targetProjectId == null) {
      return;
    }

    for (final pid in _projects.keys.toList()) {
      final p = _projects[pid]!;
      final moving = p.recordings
          .where((r) => recordingIds.contains(r.id))
          .toList();

      if (moving.isEmpty) {
        continue;
      }

      _projects[pid] = Project(
        id: p.id,
        name: p.name,
        ownerId: p.ownerId,
        recordings: p.recordings
            .where((r) => !recordingIds.contains(r.id))
            .toList(),
        users: p.users,
      );

      final target = _projects[targetProjectId]!;
      final moved = moving
          .map(
            (r) => Recording(
          id: r.id,
          name: r.name,
          source: r.source,
          thumbnailUrl: r.thumbnailUrl,
          localThumbnailPath: r.localThumbnailPath,
          localVideoPath: r.localVideoPath,
          videoTimestamp: r.videoTimestamp,
          projectId: targetProjectId,
          userId: r.userId,
          uploadStatus: r.uploadStatus,
        ),
      )
          .toList();

      _projects[targetProjectId] = Project(
        id: target.id,
        name: target.name,
        ownerId: target.ownerId,
        recordings: [...target.recordings, ...moved],
        users: target.users,
      );
    }

    for (final entry in _projects.entries) {
      projectRecordingsSync?.call(entry.key, entry.value.recordings);
    }
  }

  @override
  Future<Project> createProject(String name) => throw UnimplementedError();

  @override
  Future<void> renameProject(String projectId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();

  @override
  Future<ProjectMetadata> duplicateProject(String projectId) =>
      throw UnimplementedError();

  @override
  Future<ProjectMetadata> createLocalProject({required String name, String? id}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteLocalProject(String projectId) => throw UnimplementedError();

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

class _RecordingTestRecordingService implements RecordingService {
  final Map<String, List<Recording>> projectRecordings;
  final _RecordingTestProjectService? projectService;

  _RecordingTestRecordingService({
    required this.projectRecordings,
    this.projectService,
  }) {
    if (projectService != null) {
      projectService!.projectRecordingsSync = _syncRecordings;
    }
  }

  void _syncRecordings(String projectId, List<Recording> recordings) {
    projectRecordings[projectId] = List.of(recordings);
  }

  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    return List.of(projectRecordings[projectId] ?? const []);
  }

  @override
  Future<void> deleteCloudRecording(String recordingId) async {
    for (final key in projectRecordings.keys.toList()) {
      projectRecordings[key] = projectRecordings[key]!
          .where((r) => r.id != recordingId)
          .toList();

      final p = projectService?._projects[key];
      if (p != null) {
        projectService!._projects[key] = Project(
          id: p.id,
          name: p.name,
          ownerId: p.ownerId,
          recordings: projectRecordings[key]!,
          users: p.users,
        );
      }
    }
  }

  @override
  Future<List<Recording>> duplicateCloudRecordings({
    required List<String> recordingIds,
    String? projectId,
  }) async {
    final dst = projectId ?? projectRecordings.keys.first;
    final list = List<Recording>.from(projectRecordings[dst] ?? const []);
    final added = <Recording>[];

    for (final id in recordingIds) {
      final original = list.firstWhere((r) => r.id == id);
      final newRec = Recording(
        id: '${id}_copy',
        name: '${original.name} Copy',
        source: original.source,
        thumbnailUrl: original.thumbnailUrl,
        localThumbnailPath: original.localThumbnailPath,
        localVideoPath: original.localVideoPath,
        videoTimestamp: DateTime.now().toUtc(),
        projectId: dst,
        userId: original.userId,
        uploadStatus: original.uploadStatus,
      );
      list.add(newRec);
      added.add(newRec);
    }

    projectRecordings[dst] = list;

    final p = projectService?._projects[dst];
    if (p != null) {
      projectService!._projects[dst] = Project(
        id: p.id,
        name: p.name,
        ownerId: p.ownerId,
        recordings: list,
        users: p.users,
      );
    }

    return added;
  }

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
  Future<bool> deleteLocalRecording({
    required String projectId,
    required String recordingId,
  }) => throw UnimplementedError();

  @override
  Future<Recording> getLocalRecording(String projectId, String recordingId) =>
      throw UnimplementedError();

  @override
  Future<List<Recording>> getLocalRecordings() => throw UnimplementedError();

  @override
  Future<List<Sensor>> getLocalRecordingSensors(
      String projectId,
      String recordingId,
      ) => throw UnimplementedError();

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