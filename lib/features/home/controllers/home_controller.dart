import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/app/utils/helpers.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';

import '../../../api/client_dio.dart';
import '../../../api/models/project/project_role.dart';
import '../state/home_state.dart';

typedef ToastSink = void Function(ToastEvent);

final homeControllerProvider = Provider<HomeController>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final userService = ref.read(userServiceProvider);
  final recordingService = ref.read(recordingServiceProvider);
  final homeState = ref.read(homeStateProvider.notifier);
  final authState = ref.watch(sessionProvider);
  final localMedia = ref.read(localMediaProvider);

  void toast(ToastEvent event) => emitToast(ref, event);

  return HomeController(
    projectService: projectService,
    userService: userService,
    recordingService: recordingService,
    homeState: homeState,
    authState: authState,
    toast: toast,
    localMedia: localMedia,
  );
});

class HomeController {
  HomeController({
    required ProjectService projectService,
    required UserService userService,
    required RecordingService recordingService,
    required HomeStateNotifier homeState,
    required AuthState authState,
    required ToastSink toast,
    required LocalMedia localMedia,
  })  : _projectService = projectService,
        _recordingService = recordingService,
        _state = homeState,
        _authState = authState,
        _toast = toast,
        _localMedia = localMedia;

  final ProjectService _projectService;
  final RecordingService _recordingService;
  final HomeStateNotifier _state;
  final AuthState _authState;
  final ToastSink _toast;
  final LocalMedia _localMedia;

  HomeState get state => _state.current;

  void _error(Object e, {String? userMessage}) {
    final msg = userMessage ?? e.toString();
    _state.setErrorMessage(msg);
    _toast(ToastEvent.error(msg));
  }

  void _success(String message) => _toast(ToastEvent.success(message));

  bool _projectExists(String projectId, List<ProjectMetadata> projects) =>
      projects.any((p) => p.id == projectId);

  bool _nameExists(String name, {String? excludeProjectId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized == 'default') return true;

    return state.projects.any((p) {
      if (excludeProjectId != null && p.id == excludeProjectId) return false;
      return p.name.trim().toLowerCase() == normalized;
    });
  }

  String _duplicateName(String name) {
    final base = '$name (Copy)';
    var candidate = base;
    var i = 2;
    while (_nameExists(candidate)) {
      candidate = '$base $i';
      i++;
    }
    return candidate;
  }

  ProjectMetadata? _findById(String id) {
    for (final p in state.projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ProjectMetadata> _withDefault(List<ProjectMetadata> projects) {
    final ProjectMetadata defaultItem = _authState.isGuest
        ? ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')
        : ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default');

    return [
      defaultItem,
      ...projects.where((p) => p.id != LocalMedia.defaultProjectId),
    ];
  }

  List<ProjectMetadata> _mergeProjects(
      List<ProjectMetadata> local,
      List<ProjectMetadata> cloud,
      ) {
    final cloudIds = cloud.map((c) => c.id).toSet();
    return [...local.where((l) => !cloudIds.contains(l.id)), ...cloud];
  }

  List<Recording> _mergeRecordings(List<Recording> local, List<Recording> cloud) {
    return [...local, ...cloud];
  }

  Recording? _findRecordingById(String id) {
    for (final r in state.recordings) {
      if (r.id == id) return r;
    }
    return null;
  }

  String _newRecordingId() => Helpers.getRecordingId();

  bool _recordingNameExists(String name) {
    final normalized = name.trim().toLowerCase();
    return state.recordings.any((r) => r.name.trim().toLowerCase() == normalized);
  }


  String _duplicateRecordingName(String name) {
    final base = '$name (Copy)';
    var candidate = base;
    var i = 2;
    while (_recordingNameExists(candidate)) {
      candidate = '$base $i';
      i++;
    }
    return candidate;
  }

  Future<bool> _canManageRecordingsAsync() async {
    final project = _findById(state.openProjectId);
    if (project == null) return false;
    if (project.id == LocalMedia.defaultProjectId) return true;

    if (project.projectSource == ProjectSource.local) return true;
    if (_authState.isGuest) return true;

    final myUserId = _authState.user!.userId;

    if (state.projectUsers.isEmpty) {
      try {
        final users = await _projectService.getProjectUsers(state.openProjectId);
        _state.setProjectUsers(users);
      } catch (_) {
        return false;
      }
    }

    final me = state.projectUsers
        .where((u) => u.userId == myUserId)
        .toList()
        .firstOrNull;

    if (me == null) return false;
    return me.role is Owner || me.role is Editor;
  }

  Future<bool> canMoveToCloudProject({
    required String targetProjectId,
    required String myUserId,
  }) async {
    try {
      final users = await _projectService.getProjectUsers(targetProjectId);

      final me = users.where((u) => u.userId == myUserId).toList();
      if (me.isEmpty) {
        _toast(const ToastEvent.error('No permission'));
        return false;
      }

      final role = me.first.role;
      final canWrite = role is Owner || role is Editor;

      if (!canWrite) {
        _toast(const ToastEvent.error('No permission'));
        return false;
      }

      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) {
        _toast(const ToastEvent.error('No permission'));
        return false;
      }
      _toast(const ToastEvent.error('Failed to check permissions'));
      return false;
    } catch (_) {
      _toast(const ToastEvent.error('Failed to check permissions'));
      return false;
    }
  }


  Future<void> _refreshOpenProjectRecordings() async {
    await openProject(state.openProjectId);
  }

  // ----------------
  // Load/Open
  // ----------------

  Future<void> loadProjects() async {
    if (state.areProjectsLoaded) return;

    _state.setLoading(true);
    try {
      final localProjects = await _projectService.getLocalProjects();

      final List<ProjectMetadata> merged;
      if (!_authState.isGuest) {
        final remoteProjects = await _projectService.getProjects();
        merged = _mergeProjects(localProjects, remoteProjects);
      } else {
        merged = localProjects;
      }

      final projects = _withDefault(merged);
      _state.setProjects(projects);

      final currentOpenId = state.openProjectId;
      final openStillValid = currentOpenId == LocalMedia.defaultProjectId ||
          _projectExists(currentOpenId, projects);

      await openProject(openStillValid ? currentOpenId : LocalMedia.defaultProjectId);

      _state.setProjectsLoaded(true);
    } on DioException catch (e) {
      _error(e, userMessage: 'Failed to load projects');
    } catch (e) {
      _error(e, userMessage: 'Failed to load projects');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> openProject(String projectId) async {
    final project = _findById(projectId);
    if (project == null) {
      _toast(ToastEvent.error('Invalid project id: $projectId'));
      return;
    }

    final isDefault = projectId == LocalMedia.defaultProjectId;
    final hasCloud = project.projectSource == ProjectSource.cloud;

    try {
      final localRecordings =
      await _recordingService.getLocalProjectRecordings(projectId);

      final List<Recording> recordings;
      if (hasCloud) {
        final List<Recording> cloud;
        if (isDefault) {
          cloud = await _recordingService.getRecordings();
        } else {
          cloud = (await _projectService.getProject(projectId)).recordings;
        }
        recordings = _mergeRecordings(localRecordings, cloud);
      } else {
        recordings = localRecordings;
      }

      _state.clearUsersPopupState();
      _state.setOpenProject(projectId: projectId, recordings: recordings);
    } on DioException catch (e) {
      _error(e, userMessage: 'Failed to load project with id $projectId');
    } catch (e) {
      _error(e, userMessage: 'Failed to load project with id $projectId');
    }
  }

  Future<void> handleProjectTap(String projectId) async {
    if (state.isProjectSelectionMode) {
      toggleProjectSelection(projectId);
      return;
    }
    if (state.openProjectId == projectId) return;

    _state.setLoading(true);
    try {
      await openProject(projectId);
    } finally {
      _state.setLoading(false);
    }
  }

  // ----------------
  // Create/Rename/Delete/Duplicate Projects
  // ----------------

  Future<void> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _toast(const ToastEvent.error('Project name can’t be empty'));
      return;
    }
    if (_nameExists(trimmed)) {
      _toast(const ToastEvent.error('A project with this name already exists'));
      return;
    }

    _state.setLoading(true);
    try {
      final ProjectMetadata created;
      if (_authState.isGuest) {
        created = await _projectService.createLocalProject(name: trimmed);
      } else {
        created = (await _projectService.createProject(trimmed)).toMetadata();
      }

      _state.addProject(created);
      _state.clearError();
      _success('Project "$trimmed" created');
    } catch (e) {
      _error(e, userMessage: 'Failed to create project');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> renameProject(String projectId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _toast(const ToastEvent.error('Project name can’t be empty'));
      return;
    }
    if (_nameExists(trimmed, excludeProjectId: projectId)) {
      _toast(const ToastEvent.error('A project with this name already exists'));
      return;
    }

    final project = _findById(projectId);
    if (project == null) {
      _toast(ToastEvent.error('Invalid project id: $projectId'));
      return;
    }

    _state.setLoading(true);
    try {
      final updatedProject = project.copyWith(name: trimmed);

      if (project.projectSource == ProjectSource.cloud) {
        await _projectService.renameProject(projectId, trimmed);
      }
      await _projectService.updateLocalProject(project: updatedProject);

      _state.renameProjectInList(projectId, trimmed);
      _state.clearError();
      _success('Rename successful');
    } catch (e) {
      _error(e, userMessage: 'Failed to rename project');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> deleteProjects(Set<String> projectIds) async {
    var successCount = 0;
    final failed = <String>[];

    _state.setLoading(true);
    try {
      for (final projectId in projectIds) {
        if (projectId == LocalMedia.defaultProjectId) {
          failed.add(projectId);
          continue;
        }

        final project = _findById(projectId);
        if (project == null) {
          failed.add(projectId);
          _toast(ToastEvent.error('Invalid project id: $projectId'));
          continue;
        }

        try {
          if (project.projectSource == ProjectSource.cloud) {
            await _projectService.deleteProject(projectId);
          }
          await _projectService.deleteLocalProject(projectId);

          final wasOpen = state.openProjectId == projectId;
          _state.removeProject(projectId);

          if (wasOpen) {
            await openProject(LocalMedia.defaultProjectId);
          }

          successCount++;
        } catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to delete project ${project.name}');
        }
      }

      if (failed.isEmpty) {
        _state.clearError();
        _success(successCount == 1 ? 'Project deleted' : 'Projects deleted');
      } else {
        _toast(ToastEvent.error('Deleted $successCount, failed ${failed.length}'));
      }
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> duplicateProjects(Set<String> projectIds) async {
    var successCount = 0;
    final failed = <String>[];

    _state.setLoading(true);
    try {
      for (final projectId in projectIds) {
        if (projectId == LocalMedia.defaultProjectId) {
          failed.add(projectId);
          continue;
        }

        final project = _findById(projectId);
        if (project == null) {
          failed.add(projectId);
          _toast(ToastEvent.error('Invalid project id: $projectId'));
          continue;
        }

        try {
          late final ProjectMetadata newProject;

          if (project.projectSource == ProjectSource.cloud) {
            newProject = await _projectService.duplicateProject(projectId);
          } else {
            final newName = _duplicateName(project.name);
            final newId = Helpers.getProjectId();
            newProject = ProjectMetadata.local(newId, newName);
          }

          await _projectService.duplicateLocalProject(projectId, newProject);
          _state.addProject(newProject);
          successCount++;
        } catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to duplicate project ${project.name}');
        }
      }

      if (failed.isEmpty) {
        _state.clearError();
        _success(successCount == 1 ? 'Project duplicated' : 'Projects duplicated');
      } else {
        _toast(ToastEvent.error('Duplicated $successCount, failed ${failed.length}'));
      }
    } finally {
      _state.setLoading(false);
    }
  }

  // ----------------
  // Project Selection UI state
  // ----------------

  void enterSelectionMode({String? initialProjectId}) {
    final ids = <String>{};
    if (initialProjectId != null && initialProjectId != LocalMedia.defaultProjectId) {
      ids.add(initialProjectId);
    }
    _state.setProjectSelection(ids);
  }

  void exitProjectSelectionMode() => _state.clearProjectSelection();

  void toggleProjectSelection(String projectId) {
    if (projectId == LocalMedia.defaultProjectId) return;

    final next = Set<String>.from(state.selectedProjectIds);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }
    _state.setProjectSelection(next);
  }

  void handleProjectLongPress(String projectId) {
    if (projectId == LocalMedia.defaultProjectId) return;
    if (!state.isProjectSelectionMode) {
      _state.setProjectSelection({projectId});
    }
  }

  // ----------------
  // Recording selection UI state
  // ----------------

  void exitRecordingSelectionMode() => _state.clearRecordingSelection();

  void toggleRecordingSelection(String recordingId) {
    final next = Set<String>.from(state.selectedRecordingIds);
    if (next.contains(recordingId)) {
      next.remove(recordingId);
    } else {
      next.add(recordingId);
    }
    _state.setRecordingSelection(next);
  }


  Future<void> handleRecordingLongPress(String recordingId) async {
    if (!await _canManageRecordingsAsync()) {
      _toast(const ToastEvent.error('No permission to manage recordings'));
      return;
    }
    if (!state.isRecordingSelectionMode) {
      _state.setRecordingSelection({recordingId});
    }
  }

  Future<void> deleteRecordings(Set<String> recordingIds) async {
    if (recordingIds.isEmpty) return;

    final projectId = state.openProjectId;

    final localIds = <String>[];
    final cloudIds = <String>[];

    for (final id in recordingIds) {
      final rec = _findRecordingById(id);
      if (rec == null) continue;

      if (rec.isLocal) {
        localIds.add(id);
      } else {
        cloudIds.add(id);
      }
    }

    var successCount = 0;
    final failed = <String>[];

    _state.setLoading(true);
    try {
      // ----- Local delete -----
      for (final id in localIds) {
        final rec = _findRecordingById(id);
        if (rec == null) {
          failed.add(id);
          continue;
        }

        try {
          final ok = await _recordingService.deleteLocalRecording(
            projectId: projectId,
            recordingId: id,
          );
          if (ok) {
            successCount++;
          } else {
            failed.add(id);
          }
        } catch (e) {
          failed.add(id);
          _error(e, userMessage: 'Failed to delete recording "${rec.name}"');
        }
      }

      // ----- Cloud delete -----
      for (final id in cloudIds) {
        final rec = _findRecordingById(id);
        if (rec == null) {
          failed.add(id);
          continue;
        }

        try {
          await _recordingService.deleteCloudRecording(id);
          successCount++;
        } on DioException catch (e) {
          failed.add(id);

          final code = e.response?.statusCode;
          if (code == 403) {
            _toast(const ToastEvent.error('No permission'));
          } else {
            _error(e, userMessage: 'Failed to delete recording "${rec.name}"');
          }
        } catch (e) {
          failed.add(id);
          _error(e, userMessage: 'Failed to delete recording "${rec.name}"');
        }
      }

      await _refreshOpenProjectRecordings();
      _state.clearRecordingSelection();

      if (failed.isEmpty) {
        _success(successCount == 1 ? 'Recording deleted' : 'Recordings deleted');
      } else {
        _toast(ToastEvent.error('Deleted $successCount, failed ${failed.length}'));
      }
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> duplicateRecordings(Set<String> recordingIds) async {
    if (recordingIds.isEmpty) return;

    final projectId = state.openProjectId;

    final localIds = <String>[];
    final cloudIds = <String>[];

    for (final id in recordingIds) {
      final rec = _findRecordingById(id);
      if (rec == null) continue;

      if (rec.isLocal) {
        localIds.add(id);
      } else {
        cloudIds.add(id);
      }
    }

    var successCount = 0;
    final failed = <String>[];

    _state.setLoading(true);
    try {
      // ----- Local duplicate -----
      for (final id in localIds) {
        final rec = _findRecordingById(id);
        if (rec == null) {
          failed.add(id);
          continue;
        }

        try {
          final newId = _newRecordingId();
          final newName = _duplicateRecordingName(rec.name);

          final ok = await _recordingService.duplicateLocalRecording(
            projectId: projectId,
            sourceRecordingId: id,
            newRecordingId: newId,
            newName: newName,
          );

          if (ok) {
            successCount++;
          } else {
            failed.add(id);
          }
        } catch (e) {
          failed.add(id);
          _error(e, userMessage: 'Failed to duplicate recording "${rec.name}"');
        }
      }

      // ----- Cloud duplicate -----
      if (cloudIds.isNotEmpty) {
        try {
          final openId = state.openProjectId;
          final isDefault = openId == LocalMedia.defaultProjectId;

          final duplicated = await _recordingService.duplicateCloudRecordings(
            recordingIds: cloudIds,
            projectId: isDefault ? null : openId,
          );

          if (duplicated.isEmpty) {
            failed.addAll(cloudIds);
            _toast(const ToastEvent.error('No recordings duplicated from cloud'));
          } else {
            successCount += duplicated.length;
          }
        } on DioException catch (e) {
          failed.addAll(cloudIds);

          final code = e.response?.statusCode;
          if (code == 403) {
            _toast(const ToastEvent.error('No permission'));
          } else {
            _error(e, userMessage: 'Failed to duplicate cloud recordings');
          }
        } catch (e) {
          failed.addAll(cloudIds);
          _error(e, userMessage: 'Failed to duplicate cloud recordings');
        }
      }

      await _refreshOpenProjectRecordings();
      _state.clearRecordingSelection();

      if (failed.isEmpty) {
        _success(successCount == 1 ? 'Recording duplicated' : 'Recordings duplicated');
      } else {
        _toast(ToastEvent.error('Duplicated $successCount, failed ${failed.length}'));
      }
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> moveRecordings(
      Set<String> recordingIds, {
        required String targetProjectId,
      }) async {
    if (recordingIds.isEmpty) return;

    final sourceProjectId = state.openProjectId;
    if (targetProjectId == sourceProjectId) return;

    final localIds = <String>[];
    final cloudIds = <String>[];

    for (final id in recordingIds) {
      final rec = _findRecordingById(id);
      if (rec == null) continue;

      if (rec.source == RecordingSource.local) {
        localIds.add(id);
      } else {
        cloudIds.add(id);
      }
    }

    final targetMeta = _findById(targetProjectId);

    final targetAllowsLocal = targetProjectId == LocalMedia.defaultProjectId ||
        (targetMeta != null && targetMeta.projectSource == ProjectSource.local);

    final targetAllowsCloud = targetProjectId == LocalMedia.defaultProjectId ||
        (targetMeta != null && targetMeta.projectSource == ProjectSource.cloud);

    if (!targetAllowsLocal && localIds.isNotEmpty) {
      _toast(const ToastEvent.error('You can only move local→local or cloud→cloud'));
      return;
    }

    if (!targetAllowsCloud && cloudIds.isNotEmpty) {
      _toast(const ToastEvent.error('You can only move local→local or cloud→cloud'));
      return;
    }

    var successCount = 0;
    final failed = <String>[];

    _state.setLoading(true);
    try {
      // ---- Local move (filesystem) ----
      if (localIds.isNotEmpty) {
        for (final id in localIds) {
          final rec = _findRecordingById(id);
          if (rec == null) {
            failed.add(id);
            continue;
          }

          try {
            final srcDir = _localMedia.recordingDir(sourceProjectId, id);
            final dstDir = _localMedia.recordingDir(targetProjectId, id);

            if (!await srcDir.exists()) {
              failed.add(id);
              continue;
            }

            await dstDir.parent.create(recursive: true);
            await srcDir.rename(dstDir.path);
            successCount++;
          } catch (e) {
            failed.add(id);
            _error(e, userMessage: 'Failed to move recording "${rec.name}"');
          }
        }
      }

      // ---- Cloud move ----
      if (cloudIds.isNotEmpty) {
        final myUserId = _authState.user?.userId;
        if (myUserId == null) {
          _toast(const ToastEvent.error('No permission'));
          return;
        }

        final canMove = await canMoveToCloudProject(
          targetProjectId: targetProjectId,
          myUserId: myUserId,
        );

        if (!canMove) {
          return;
        }

        try {
          await _projectService.moveRecordings(
            recordingIds: cloudIds,
            targetProjectId:
            targetProjectId == LocalMedia.defaultProjectId ? null : targetProjectId,
          );
          successCount += cloudIds.length;
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          if (code == 403) {
            _toast(const ToastEvent.error('No permission'));
            return;
          }
          _error(e, userMessage: 'Failed to move cloud recordings');
          return;
        } catch (e) {
          _error(e, userMessage: 'Failed to move cloud recordings');
          return;
        }
      }
    } finally {
      _state.setLoading(false);

      await _refreshOpenProjectRecordings();
      _state.clearRecordingSelection();

      if (failed.isEmpty) {
        if (successCount > 0) {
          _success(successCount == 1 ? 'Recording moved' : 'Recordings moved');
        }
      } else {
        _toast(ToastEvent.error('Moved $successCount, failed ${failed.length}'));
      }
    }
  }

  // ----------------
  // Project users popup
  // ----------------

  Future<void> loadUsersForOpenProject({required String myUserId}) async {
    final projectId = state.openProjectId;
    if (projectId == LocalMedia.defaultProjectId) return;

    _state.setUsersLoading(true);

    try {
      final users = await _projectService.getProjectUsers(projectId);
      _state.setProjectUsers(users);
    } on DioException {
      const msg = 'Failed to load project users';
      _state.setUsersError(msg);
      _toast(const ToastEvent.error(msg));
    } catch (_) {
      const msg = 'Failed to load project users';
      _state.setUsersError(msg);
      _toast(const ToastEvent.error(msg));
    }
  }

  Future<void> addUserToOpenProject({
    required String? myUserId,
    required String emailAddress,
    required ProjectRoleType role,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == LocalMedia.defaultProjectId) {
      _toast(const ToastEvent.error('Select a project first'));
      return;
    }

    final email = emailAddress.trim();
    if (email.isEmpty) return;

    _state.setUsersLoading(true);

    try {
      final updatedUsers = await _projectService.addProjectUser(
        projectId: projectId,
        emailAddress: email,
        role: role,
      );

      _state.setProjectUsers(updatedUsers);
      _toast(const ToastEvent.success('User added'));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 409) {
        _toast(const ToastEvent.error('User already in project'));
        return;
      }
      if (code == 403) {
        _toast(const ToastEvent.error('No permission'));
        return;
      }
      if (code == 404) {
        _toast(const ToastEvent.error('User not found'));
        return;
      }

      _toast(const ToastEvent.error('Failed to add user'));
    } catch (_) {
      _toast(const ToastEvent.error('Failed to add user'));
    } finally {
      _state.setUsersLoading(false);
    }
  }

  Future<void> removeUserFromOpenProject({
    required String myUserId,
    required String userId,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == LocalMedia.defaultProjectId) return;

    _state.setUsersLoading(true);

    try {
      await _projectService.removeUserFromProject(
        projectId: projectId,
        userId: userId,
      );

      final users = await _projectService.getProjectUsers(projectId);
      _state.setProjectUsers(users);

      _toast(const ToastEvent.success('User removed'));
    } catch (_) {
      _state.setUsersLoading(false);
      _toast(const ToastEvent.error('Failed to remove user'));
    }
  }

  void clearUsersPopupState() => _state.clearUsersPopupState();
}
