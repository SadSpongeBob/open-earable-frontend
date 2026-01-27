import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording//recording_service.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../state/home_state.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
      (ref) {
    final projectService = ref.read(projectServiceProvider);
    final recordingService = ref.read(recordingServiceProvider);

    void toast(ToastEvent event) => emitToast(ref, event);

    return HomeController(recordingService: recordingService,
        projectService: projectService,
        toast: toast);
  },
);

typedef ToastSink = void Function(ToastEvent);

class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required RecordingService recordingService,
    required ProjectService projectService,
    required ToastSink toast,
  })  : _recordingService = recordingService,
        _projectService = projectService,
        _toast = toast,
        super(HomeState.initial());

  final RecordingService _recordingService;
  final ProjectService _projectService;
  final ToastSink _toast;

  void _setLoading(bool value) =>
      state = state.copyWith(isLoading: value);

  void _setError(Object e, {String? userMessage}) {
    final msg = userMessage ?? e.toString();
    state = state.copyWith(isLoading: false, errorMessage: msg);
    _toast(ToastEvent.error(msg));
  }

  void _success(String message) => _toast(ToastEvent.success(message));

  bool _projectExists(String projectId, List<ProjectMetadata> projects) =>
      projects.any((p) => p.id == projectId);

  bool _nameExists(String name, {String? excludeProjectId}) {
    final normalized = name.trim().toLowerCase();
    return state.projects.any((p) {
      if (excludeProjectId != null && p.id == excludeProjectId) return false;
      return p.name.trim().toLowerCase() == normalized || normalized == 'default';
    });
  }

  ProjectMetadata? _findById(String id) {
    for (final p in state.projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> loadProjects() async {
    _setLoading(true);
    try {
      final projects = await _projectService.getProjects();

      final currentOpenId = state.openProjectId;
      final openStillValid =
          currentOpenId == 'default' || _projectExists(currentOpenId, projects);

      state = state.copyWith(projects: projects);
      await openProject(openStillValid ? currentOpenId : 'default');
    } on DioException catch (e) {
      _setError(e, userMessage: 'Failed to load projects');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openProject(String projectId) async {
    final isDefault = projectId == 'default';

    final isValid =
        isDefault || _projectExists(projectId, state.projects);
    if (!isValid) {
      _setError(
          projectId, userMessage: 'Failed to load project with id $projectId');
      return;
    }

    try {
      List<Recording> recordings;
      if (isDefault) {
        recordings = await _recordingService.getRecordings();
      } else {
        final project = await _projectService.getProject(projectId);
        recordings = project.recordings;
      }

      state = state.copyWith(
        openProjectId: projectId,
        videos: recordings,
        clearSelectedVideoId: true,
        clearError: true,
      );
    } on DioException catch (e) {
      _setError(e, userMessage: 'Failed to load project with id $projectId');
    }
  }

  Future<void> openDefaultProject() => openProject('default');

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

    _setLoading(true);
    try {
      final created = await _projectService.createProject(trimmed);

      state = state.copyWith(
        isLoading: false,
        videos: [],
        projects: [...state.projects, created.toMetadata()],
        openProjectId: created.id,
        clearError: true,
      );

      _success('Project "$trimmed" created');
    } catch (e) {
      _setError(e, userMessage: 'Failed to create project');
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

    _setLoading(true);
    try {
      await _projectService.renameProject(projectId, trimmed);

      final updatedProjects = state.projects.map((p) {
        if (p.id != projectId) return p;
        return p.copyWith(name: trimmed);
      }).toList();

      state = state.copyWith(
        isLoading: false,
        projects: updatedProjects,
        clearError: true,
      );

      _success('Rename Successful');
    } catch (e) {
      _setError(e, userMessage: 'Failed to rename project');
    }
  }

  Future<void> deleteProject(String projectId) async {
    _setLoading(true);
    try {
      await _projectService.deleteProject(projectId);

      final updated = state.projects.where((p) => p.id != projectId).toList();
      var newOpenId = state.openProjectId;
      if (state.openProjectId == projectId) {
        await openProject('default');
        newOpenId = 'default';
      }

      final nextSelected = Set<String>.from(state.selectedProjectIds)
        ..remove(projectId);

      state = state.copyWith(
        projects: updated,
        openProjectId: newOpenId,
        selectedProjectIds: nextSelected,
        isSelectionMode: state.isSelectionMode && nextSelected.isNotEmpty,
        clearError: true,
      );

      _success('Project Deleted');
    } on DioException catch (e) {
      _setError(e, userMessage: 'Failed to delete project');
    } finally {
      _setLoading(false);
    }
  }

  void enterSelectionMode({String? initialProjectId}) {
    final ids = <String>{};
    if (initialProjectId != null && initialProjectId != 'default') {
      ids.add(initialProjectId);
    }

    state = state.copyWith(
      isSelectionMode: true,
      selectedProjectIds: ids,
      clearError: true,
    );
  }

  void exitSelectionMode() {
    state = state.copyWith(
      isSelectionMode: false,
      selectedProjectIds: <String>{},
      clearError: true,
    );
  }

  void toggleProjectSelection(String projectId) {

    final next = Set<String>.from(state.selectedProjectIds);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }

    state = state.copyWith(
      isSelectionMode: next.isNotEmpty,
      selectedProjectIds: next,
      clearError: true,
    );
  }

  Future<void> handleProjectTap(String projectId) async {
    if (state.isSelectionMode) {
      toggleProjectSelection(projectId);
      return;
    }
    _setLoading(true);
    try {
      await openProject(projectId);
    } finally {
      _setLoading(false);
    }
  }

  void handleProjectLongPress(String projectId) {
    if (projectId == 'default') return;
    if (!state.isSelectionMode) {
      enterSelectionMode(initialProjectId: projectId);
    }
  }

  Future<void> duplicateProject(String projectId) async {
    if (projectId == 'default') return;

    final project = _findById(projectId);
    if (project == null) {
      _toast(const ToastEvent.error('Project not found'));
      return;
    }

    String base = '${project.name} (Copy)';
    String candidate = base;
    int i = 2;
    while (_nameExists(candidate)) {
      candidate = '$base $i';
      i++;
    }

    await createProject(candidate);
  }
}

