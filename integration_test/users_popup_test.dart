import 'dart:io';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/home/widgets/users_button.dart';
import 'package:openearable/features/home/widgets/users_popup.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project_user.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/api/models/recording/recording.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Users Popup Integration', () {
    late Directory tmp;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('openearable_users_tests');
    });

    tearDownAll(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    testWidgets('users button is visible when authenticated and cloud project open', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final project = Project(id: 'projU1', name: 'UsersProject', ownerId: 'u1', recordings: [], users: []);
      final projectService = _UsersTestProjectService(projects: {'projU1': project});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'Owner', emailAddress: 'owner@example.com', photoUrl: null));

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

      // UsersButton should be present (widget type)
      expect(find.byType(UsersButton), findsOneWidget);
    });

    testWidgets('user can open the users popup', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);
      final projectService = _UsersTestProjectService(projects: {'projU2': Project(id: 'projU2', name: 'P2', ownerId: 'u1', recordings: [], users: [])});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'Owner', emailAddress: 'owner@example.com', photoUrl: null));

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

      // Open users popup
      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      expect(find.byType(UsersPopup), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('users popup can be closed with Go Back', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);
      final projectService = _UsersTestProjectService(projects: {'projU3': Project(id: 'projU3', name: 'P3', ownerId: 'u1', recordings: [], users: [])});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'Owner', emailAddress: 'owner@example.com', photoUrl: null));

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

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      expect(find.byType(UsersPopup), findsOneWidget);

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(find.byType(UsersPopup), findsNothing);
    });

    testWidgets('popup shows empty state when there are no users', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);
      final projectService = _UsersTestProjectService(projects: {'projU4': Project(id: 'projU4', name: 'P4', ownerId: 'u1', recordings: [], users: [])});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'Owner', emailAddress: 'owner@example.com', photoUrl: null));

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

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      expect(find.text('No users in this project yet'), findsOneWidget);
    });

    testWidgets('popup shows loaded users and marks current user with You', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final user1 = ProjectUser(userId: 'u1', name: 'Owner One', emailAddress: 'owner@example.com', role: Owner(userId: 'u1'), pictureUrl: null);
      final user2 = ProjectUser(userId: 'u2', name: 'User Two', emailAddress: 'two@example.com', role: Viewer(userId: 'u2'), pictureUrl: null);

      final projectService = _UsersTestProjectService(projects: {'projU5': Project(id: 'projU5', name: 'P5', ownerId: 'u1', recordings: [], users: [])}, users: {'projU5': [user1, user2]});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u1', name: 'Owner One', emailAddress: 'owner@example.com', photoUrl: null));

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

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      // user names and emails should appear
      expect(find.text('Owner One'), findsOneWidget);
      expect(find.text('two@example.com'), findsOneWidget);

      // current user should have 'You' badge
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('owner can see add-user controls', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final ownerUser = ProjectUser(userId: 'u100', name: 'Owner100', emailAddress: 'o100@example.com', role: Owner(userId: 'u100'), pictureUrl: null);
      final projectService = _UsersTestProjectService(projects: {'projOwner': Project(id: 'projOwner', name: 'OwnerProj', ownerId: 'u100', recordings: [], users: [])}, users: {'projOwner': [ownerUser]});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u100', name: 'Owner100', emailAddress: 'o100@example.com', photoUrl: null));

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

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      // Input hint and Add button plus role label "Viewer" should be visible
      expect(find.text('User Email'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Viewer'), findsWidgets);
    });

    testWidgets('non-owner does not see add-user controls', (tester) async {
      final localMedia = LocalMedia(tmp, tmp, tmp);

      final nonOwnerUser = ProjectUser(userId: 'u200', name: 'User200', emailAddress: 'u200@example.com', role: Viewer(userId: 'u200'), pictureUrl: null);
      final projectService = _UsersTestProjectService(projects: {'projNonOwner': Project(id: 'projNonOwner', name: 'NOP', ownerId: 'uX', recordings: [], users: [])}, users: {'projNonOwner': [nonOwnerUser]});
      final recordingService = _UsersTestRecordingService();

      final authNotifier = SessionNotifier();
      authNotifier.setAuthenticated(User(userId: 'u200', name: 'User200', emailAddress: 'u200@example.com', photoUrl: null));

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

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      expect(find.text('User Email'), findsNothing);
      expect(find.text('Add'), findsNothing);
    });
  });
}

// -----------------------------
// Minimal fake ProjectService
// -----------------------------
class _UsersTestProjectService implements ProjectService {
  final Map<String, Project> projects;
  final Map<String, List<ProjectUser>> users;

  _UsersTestProjectService({required this.projects, Map<String, List<ProjectUser>>? users}) : users = users ?? {};

  @override
  Future<List<ProjectMetadata>> getProjects() async {
    return projects.values.map((p) => ProjectMetadata.cloud(p.id, p.name)).toList();
  }

  @override
  Future<List<ProjectMetadata>> getLocalProjects() async => [];

  @override
  Future<List<ProjectUser>> getProjectUsers(String projectId) async {
    return List.of(users[projectId] ?? []);
  }

  @override
  Future<List<ProjectUser>> addProjectUser({required String projectId, required String emailAddress, required ProjectRoleType role}) async {
    final id = 'u_${DateTime.now().millisecondsSinceEpoch}';
    final user = ProjectUser(userId: id, name: emailAddress.split('@').first, emailAddress: emailAddress, role: role == ProjectRoleType.owner ? Owner(userId: id) : (role == ProjectRoleType.editor ? Editor(userId: id) : Viewer(userId: id)), pictureUrl: null);
    users[projectId] = [...(users[projectId] ?? []), user];
    return List.of(users[projectId]!);
  }

  @override
  Future<void> removeUserFromProject({required String projectId, required String userId}) async {
    users[projectId] = (users[projectId] ?? []).where((u) => u.userId != userId).toList();
  }

  // Unused stubs
  @override
  Future<Project> getProject(String projectId) => throw UnimplementedError();
  @override
  Future<Project> createProject(String name) => throw UnimplementedError();
  @override
  Future<ProjectMetadata> duplicateProject(String projectId) => throw UnimplementedError();
  @override
  Future<void> renameProject(String projectId, String name) => throw UnimplementedError();
  @override
  Future<void> moveRecordings({required List<String> recordingIds, required String? targetProjectId}) => throw UnimplementedError();
  @override
  Future<void> deleteProject(String projectId) => throw UnimplementedError();
  @override
  Future<ProjectMetadata> createLocalProject({required String name, String? id}) => throw UnimplementedError();
  @override
  Future<void> deleteLocalProject(String projectId) => throw UnimplementedError();
  @override
  Future<void> duplicateLocalProject(String projectId, ProjectMetadata newProject) => throw UnimplementedError();
  @override
  Future<void> updateLocalProject({required ProjectMetadata project, String? oldProjectId}) => throw UnimplementedError();
  @override
  Future<List<String>> getLocalProjectIds() => throw UnimplementedError();
  @override
  Future<void> leaveProject({required String projectId}) => throw UnimplementedError();
  @override
  Future<void> overwriteMetaIfProjectDirExists(String projectId, ProjectMetadata project) => throw UnimplementedError();
  @override
  Future<void> updateProjectUserRole({required String projectId, required String userId, required ProjectRoleType role}) => throw UnimplementedError();
}

// -----------------------------
// Minimal fake RecordingService (no-op for these tests)
// -----------------------------
class _UsersTestRecordingService implements RecordingService {
  @override
  Future<List<Recording>> getLocalProjectRecordings(String projectId) async => [];

  // stubs for interface - not used in tests
  @override
  Future<bool> duplicateLocalRecording({required String projectId, required String sourceRecordingId, required String newRecordingId, required String newName}) => throw UnimplementedError();
  @override
  Future<GetRecordingResponse> getRecording(String recordingId) => throw UnimplementedError();
  @override
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) => throw UnimplementedError();
  @override
  Future<List<Recording>> getRecordings() => throw UnimplementedError();
  @override
  Future<Recording> completeUpload(String recordingId) => throw UnimplementedError();
  @override
  Future<void> deleteCloudRecording(String recordingId) => throw UnimplementedError();
  @override
  Future<bool> deleteLocalRecording({required String projectId, required String recordingId}) => throw UnimplementedError();
  @override
  Future<List<Recording>> getLocalRecordings() => throw UnimplementedError();
  @override
  Future<List<Sensor>> getLocalRecordingSensors(String projectId, String recordingId) => throw UnimplementedError();
  @override
  Future<void> renameCloud({required String recordingId, required String name}) => throw UnimplementedError();
  @override
  Future<void> renameLocal({required String projectId, required String recordingId, required String newName}) => throw UnimplementedError();
  @override
  Future<void> updateLocalUploadStatus(String projectId, String recordingId, UploadStatus uploadStatus) => throw UnimplementedError();
  // Additional stubs required by RecordingService interface
  @override
  Future<List<Recording>> duplicateCloudRecordings({required List<String> recordingIds, String? projectId}) => throw UnimplementedError();

  @override
  Future<Recording> getLocalRecording(String projectId, String recordingId) => throw UnimplementedError();
}
