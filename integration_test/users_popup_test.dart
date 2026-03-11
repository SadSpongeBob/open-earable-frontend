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
import 'package:openearable/features/home/widgets/users_button.dart';
import 'package:openearable/features/home/widgets/users_popup.dart';

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
      name: 'Owner User',
      emailAddress: 'owner@example.com',
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

Future<void> _openUsersPopup(WidgetTester tester) async {
  final usersButton = find.byType(UsersButton);
  expect(usersButton, findsOneWidget);
  await tester.tap(usersButton);
  await tester.pumpAndSettle();
  expect(find.byType(UsersPopup), findsOneWidget);
}

ProjectRole _ownerUser() => Owner(userId: 'u1');

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

ProjectUser _projectUser({
  required String userId,
  required String name,
  required String email,
  required ProjectRole role,
}) {
  return ProjectUser(
    userId: userId,
    name: name,
    emailAddress: email,
    pictureUrl: null,
    role: role,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Integration - Users Popup', () {
    late Directory tmp;

    setUpAll(() async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://167.71.50.147:8080\n');
      tmp = await Directory.systemTemp.createTemp('openearable_users_popup_tests');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('owner can open users popup and see project users', (
        tester,
        ) async {
      final recordings = [
        _cloudRecording(id: 'r1', name: 'Rec 1', projectId: 'proj1'),
      ];

      final projectService = _UsersTestProjectService(
        projects: {
          'proj1': Project(
            id: 'proj1',
            name: 'Project Users',
            ownerId: 'u1',
            recordings: recordings,
            users: [_ownerUser(), Viewer(userId: 'u2')],
          ),
        },
        projectUsers: {
          'proj1': [
            _projectUser(
              userId: 'u1',
              name: 'Owner User',
              email: 'owner@example.com',
              role: Owner(userId: 'u1'),
            ),
            _projectUser(
              userId: 'u2',
              name: 'Viewer User',
              email: 'viewer@example.com',
              role: Viewer(userId: 'u2'),
            ),
          ],
        },
      );

      final recordingService = _UsersTestRecordingService(
        projectRecordings: {'proj1': List.of(recordings)},
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Users');
      await _openUsersPopup(tester);

      expect(find.text('Owner User'), findsOneWidget);
      expect(find.text('Viewer User'), findsOneWidget);
      expect(find.text('owner@example.com'), findsOneWidget);
      expect(find.text('viewer@example.com'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await _disposeHome(tester);
    });

    testWidgets('owner can add a user from the users popup', (tester) async {
      final recordings = [
        _cloudRecording(id: 'r2', name: 'Rec 2', projectId: 'proj2'),
      ];

      final projectService = _UsersTestProjectService(
        projects: {
          'proj2': Project(
            id: 'proj2',
            name: 'Project Add User',
            ownerId: 'u1',
            recordings: recordings,
            users: [_ownerUser()],
          ),
        },
        projectUsers: {
          'proj2': [
            _projectUser(
              userId: 'u1',
              name: 'Owner User',
              email: 'owner@example.com',
              role: Owner(userId: 'u1'),
            ),
          ],
        },
      );

      final recordingService = _UsersTestRecordingService(
        projectRecordings: {'proj2': List.of(recordings)},
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Add User');
      await _openUsersPopup(tester);

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'newuser@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('newuser@example.com'), findsOneWidget);

      final users = await projectService.getProjectUsers('proj2');
      expect(
        users.any((u) => u.emailAddress == 'newuser@example.com'),
        isTrue,
      );

      await _disposeHome(tester);
    });

    testWidgets('owner can update a user role from the users popup', (
        tester,
        ) async {
      final recordings = [
        _cloudRecording(id: 'r3', name: 'Rec 3', projectId: 'proj3'),
      ];

      final projectService = _UsersTestProjectService(
        projects: {
          'proj3': Project(
            id: 'proj3',
            name: 'Project Update Role',
            ownerId: 'u1',
            recordings: recordings,
            users: [_ownerUser(), Viewer(userId: 'u2')],
          ),
        },
        projectUsers: {
          'proj3': [
            _projectUser(
              userId: 'u1',
              name: 'Owner User',
              email: 'owner@example.com',
              role: Owner(userId: 'u1'),
            ),
            _projectUser(
              userId: 'u2',
              name: 'Viewer User',
              email: 'viewer@example.com',
              role: Viewer(userId: 'u2'),
            ),
          ],
        },
      );

      final recordingService = _UsersTestRecordingService(
        projectRecordings: {'proj3': List.of(recordings)},
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Update Role');
      await _openUsersPopup(tester);

      expect(find.text('Viewer'), findsWidgets);

      await tester.tap(find.text('Viewer').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editor').last);
      await tester.pumpAndSettle();

      final users = await projectService.getProjectUsers('proj3');
      final updatedUser = users.firstWhere((u) => u.userId == 'u2');
      expect(updatedUser.role, isA<Editor>());

      await _disposeHome(tester);
    });

    testWidgets('owner can remove a user from the users popup', (tester) async {
      final recordings = [
        _cloudRecording(id: 'r4', name: 'Rec 4', projectId: 'proj4'),
      ];

      final projectService = _UsersTestProjectService(
        projects: {
          'proj4': Project(
            id: 'proj4',
            name: 'Project Remove User',
            ownerId: 'u1',
            recordings: recordings,
            users: [_ownerUser(), Viewer(userId: 'u2')],
          ),
        },
        projectUsers: {
          'proj4': [
            _projectUser(
              userId: 'u1',
              name: 'Owner User',
              email: 'owner@example.com',
              role: Owner(userId: 'u1'),
            ),
            _projectUser(
              userId: 'u2',
              name: 'Viewer User',
              email: 'viewer@example.com',
              role: Viewer(userId: 'u2'),
            ),
          ],
        },
      );

      final recordingService = _UsersTestRecordingService(
        projectRecordings: {'proj4': List.of(recordings)},
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Remove User');
      await _openUsersPopup(tester);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Viewer User'), findsNothing);

      final users = await projectService.getProjectUsers('proj4');
      expect(users.any((u) => u.userId == 'u2'), isFalse);

      await _disposeHome(tester);
    });

    testWidgets('user can close the users popup with go back', (tester) async {
      final recordings = [
        _cloudRecording(id: 'r5', name: 'Rec 5', projectId: 'proj5'),
      ];

      final projectService = _UsersTestProjectService(
        projects: {
          'proj5': Project(
            id: 'proj5',
            name: 'Project Close Popup',
            ownerId: 'u1',
            recordings: recordings,
            users: [_ownerUser()],
          ),
        },
        projectUsers: {
          'proj5': [
            _projectUser(
              userId: 'u1',
              name: 'Owner User',
              email: 'owner@example.com',
              role: Owner(userId: 'u1'),
            ),
          ],
        },
      );

      final recordingService = _UsersTestRecordingService(
        projectRecordings: {'proj5': List.of(recordings)},
      );

      await _pumpHome(
        tester,
        tmp: tmp,
        projectService: projectService,
        recordingService: recordingService,
      );

      await _openProject(tester, 'Project Close Popup');
      await _openUsersPopup(tester);

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(find.byType(UsersPopup), findsNothing);

      await _disposeHome(tester);
    });
  });
}

class _UsersTestProjectService implements ProjectService {
  final Map<String, Project> _projects;
  final Map<String, List<ProjectUser>> _projectUsers;

  _UsersTestProjectService({
    required Map<String, Project> projects,
    required Map<String, List<ProjectUser>> projectUsers,
  }) : _projects = Map.of(projects),
        _projectUsers = projectUsers.map(
              (key, value) => MapEntry(key, List<ProjectUser>.from(value)),
        );

  ProjectRole _roleForType(ProjectRoleType role, String userId) {
    switch (role) {
      case ProjectRoleType.owner:
        return Owner(userId: userId);
      case ProjectRoleType.editor:
        return Editor(userId: userId);
      case ProjectRoleType.viewer:
        return Viewer(userId: userId);
    }
  }

  void _syncProjectRoles(String projectId) {
    final project = _projects[projectId];
    final users = _projectUsers[projectId];
    if (project == null || users == null) return;

    _projects[projectId] = Project(
      id: project.id,
      name: project.name,
      ownerId: project.ownerId,
      recordings: project.recordings,
      users: users.map((u) => u.role).toList(),
    );
  }

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
    return List<ProjectUser>.from(_projectUsers[projectId] ?? const []);
  }

  @override
  Future<List<ProjectUser>> addProjectUser({
    required String projectId,
    required String emailAddress,
    required ProjectRoleType role,
  }) async {
    final users = List<ProjectUser>.from(_projectUsers[projectId] ?? const []);
    final email = emailAddress.trim().toLowerCase();

    if (users.any((u) => u.emailAddress.toLowerCase() == email)) {
      return users;
    }

    final nextIndex = users.length + 1;
    final userId = 'u$nextIndex';
    users.add(
      ProjectUser(
        userId: userId,
        name: 'User $nextIndex',
        emailAddress: emailAddress.trim(),
        pictureUrl: null,
        role: _roleForType(role, userId),
      ),
    );

    _projectUsers[projectId] = users;
    _syncProjectRoles(projectId);
    return List<ProjectUser>.from(users);
  }

  @override
  Future<void> updateProjectUserRole({
    required String projectId,
    required String userId,
    required ProjectRoleType role,
  }) async {
    final users = List<ProjectUser>.from(_projectUsers[projectId] ?? const []);
    final index = users.indexWhere((u) => u.userId == userId);
    if (index == -1) return;

    final old = users[index];
    users[index] = ProjectUser(
      userId: old.userId,
      name: old.name,
      emailAddress: old.emailAddress,
      pictureUrl: old.pictureUrl,
      role: _roleForType(role, old.userId),
    );

    _projectUsers[projectId] = users;
    _syncProjectRoles(projectId);
  }

  @override
  Future<void> removeUserFromProject({
    required String projectId,
    required String userId,
  }) async {
    final users = List<ProjectUser>.from(_projectUsers[projectId] ?? const []);
    users.removeWhere((u) => u.userId == userId);
    _projectUsers[projectId] = users;
    _syncProjectRoles(projectId);
  }

  @override
  Future<void> moveRecordings({
    required List<String> recordingIds,
    required String? targetProjectId,
  }) async {}

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
  Future<List<String>> getLocalProjectIds() => throw UnimplementedError();

  @override
  Future<void> leaveProject({required String projectId}) =>
      throw UnimplementedError();

  @override
  Future<void> overwriteMetaIfProjectDirExists(
      String projectId,
      ProjectMetadata project,
      ) => throw UnimplementedError();
}

class _UsersTestRecordingService implements RecordingService {
  final Map<String, List<Recording>> projectRecordings;

  _UsersTestRecordingService({required this.projectRecordings});

  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    return List.of(projectRecordings[projectId] ?? const []);
  }

  @override
  Future<void> deleteCloudRecording(String recordingId) async {}

  @override
  Future<List<Recording>> duplicateCloudRecordings({
    required List<String> recordingIds,
    String? projectId,
  }) async {
    return [];
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