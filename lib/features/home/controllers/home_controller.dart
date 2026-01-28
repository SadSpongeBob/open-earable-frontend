import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording//recording_service.dart';
import 'package:openearable/app/utils/helpers.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../state/home_state.dart';

final homeControllerProvider = Provider<HomeController>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final recordingService = ref.read(recordingServiceProvider);
  final homeState = ref.read(homeStateProvider.notifier);
  final authState = ref.watch(sessionProvider);

  void toast(ToastEvent event) => emitToast(ref, event);

  return HomeController(
    projectService: projectService,
    recordingService: recordingService,
    homeState: homeState,
    authState: authState,
    toast: toast,
  );
});

typedef ToastSink = void Function(ToastEvent);

class HomeController {
  HomeController({
    required ProjectService projectService,
    required RecordingService recordingService,
    required HomeStateNotifier homeState,
    required AuthState authState,
    required ToastSink toast,
  }) : _projectService = projectService,
       _recordingService = recordingService,
       _state = homeState,
       _authState = authState,
       _toast = toast;

  final ProjectService _projectService;
  final RecordingService _recordingService;
  final HomeStateNotifier _state;
  final AuthState _authState;
  final ToastSink _toast;

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

  List<ProjectMetadata> _withDefault(List<ProjectMetadata> remoteProjects) {
    final defaultItem = ProjectMetadata.local(
      LocalMedia.defaultProjectId,
      'Default',
    );

    return [
      defaultItem,
      ...remoteProjects.where((p) => p.id != LocalMedia.defaultProjectId),
    ];
  }

  List<ProjectMetadata> _mergeProjects(
    List<ProjectMetadata> local,
    List<ProjectMetadata> cloud,
  ) {
    final cloudIds = cloud.map((c) => c.id).toSet();

    return [...local.where((l) => !cloudIds.contains(l.id)), ...cloud];
  }

  List<Recording> _mergeRecordings(
    List<Recording> local,
    List<Recording> cloud,
  ) {
    return [...local, ...cloud];
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
      final openStillValid =
          currentOpenId == LocalMedia.defaultProjectId ||
          _projectExists(currentOpenId, projects);

      await openProject(
        openStillValid ? currentOpenId : LocalMedia.defaultProjectId,
      );
      _state.setProjectsLoaded(true);
    } on DioException catch (e) {
      _error(e, userMessage: 'Failed to load projects');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> openProject(String projectId) async {
    final isDefault = projectId == LocalMedia.defaultProjectId;
    final isValid = isDefault || _projectExists(projectId, state.projects);

    if (!isValid) {
      _toast(ToastEvent.error('Invalid project id: $projectId'));
      return;
    }

    try {
      final localRecordings = await _recordingService.getLocalProjectRecordings(
        projectId,
      );
      final List<Recording> recordings;
      if (_authState.isGuest) {
        recordings = localRecordings;
      } else {
        final List<Recording> cloud;
        if (isDefault) {
          cloud = await _recordingService.getRecordings();
        } else {
          cloud = (await _projectService.getProject(projectId)).recordings;
        }

        recordings = _mergeRecordings(localRecordings, cloud);
      }

      _state.setOpenProject(projectId: projectId, videos: recordings);
    } on DioException catch (e) {
      _error(e, userMessage: 'Failed to load project with id $projectId');
    }
  }

  Future<void> handleProjectTap(String projectId) async {
    if (state.isSelectionMode) {
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
  // Create/Rename/Delete/Duplicate
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
      _state.setOpenProject(projectId: created.id, videos: const []);

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
      _success('Rename Successful');
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
        final project = _findById(projectId);
        if (project == null) {
          _toast(ToastEvent.error('Invalid project id: $projectId'));
          failed.add(projectId);
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
        } on DioException catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to delete project ${project.name}');
        } catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to delete project ${project.name}');
        }
      }

      if (failed.isEmpty) {
        _state.clearError();
        _success(successCount == 1 ? 'Project deleted' : 'Projects deleted');
      } else {
        _toast(
          ToastEvent.error('Deleted $successCount, failed ${failed.length}'),
        );
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
          failed.add(projectId); // or continue without counting
          continue;
        }

        final project = _findById(projectId);
        if (project == null) {
          _toast(ToastEvent.error('Invalid project id: $projectId'));
          failed.add(projectId);
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
        } on DioException catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to duplicate project ${project.name}');
        } catch (e) {
          failed.add(projectId);
          _error(e, userMessage: 'Failed to duplicate project ${project.name}');
        }
      }

      if (failed.isEmpty) {
        _state.clearError();
        _success(
          successCount == 1 ? 'Project duplicated' : 'Projects duplicated',
        );
      } else {
        _toast(
          ToastEvent.error('Duplicated $successCount, failed ${failed.length}'),
        );
      }
    } finally {
      _state.setLoading(false);
    }
  }

  // ----------------
  // Selection UI state
  // ----------------

  void enterSelectionMode({String? initialProjectId}) {
    final ids = <String>{};
    if (initialProjectId != null &&
        initialProjectId != LocalMedia.defaultProjectId) {
      ids.add(initialProjectId);
    }

    _state.setSelection(ids);
  }

  void exitSelectionMode() {
    _state.clearSelection();
  }

  void toggleProjectSelection(String projectId) {
    if (projectId == LocalMedia.defaultProjectId) return;
    final next = Set<String>.from(state.selectedProjectIds);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }

    _state.setSelection(next);
  }

  void handleProjectLongPress(String projectId) {
    if (projectId == LocalMedia.defaultProjectId) return;
    if (!state.isSelectionMode) {
      _state.setSelection({projectId});
    }
  }
}
