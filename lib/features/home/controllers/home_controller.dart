import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/services/project/project_service.dart';
import '../../../api/client_dio.dart';
import '../../../api/models/project.dart';
import '../state/home_state.dart';

final homeControllerProvider =
StateNotifierProvider<HomeController, HomeState>((ref) {
  final projectService = ref.read(projectServiceProvider);
  return HomeController(projectService: projectService);
});

class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required ProjectService projectService,
  })  : _projectService = projectService,
        super(HomeState.initial());

  final ProjectService _projectService;

  void _setLoading(bool value) =>
      state = state.copyWith(isLoading: value, clearError: value);

  void _setError(Object e) =>
      state = state.copyWith(isLoading: false, errorMessage: e.toString());

  bool _projectExists(String projectId, List<Project> projects) =>
      projects.any((p) => p.id == projectId);

  bool _projectNameExists(String name) {
    final normalized = name.trim().toLowerCase();

    return state.projects.any(
          (p) => p.name.trim().toLowerCase() == normalized,
    );
  }


  Future<void> loadProjects() async {
    _setLoading(true);
    try {
      final projects = await _projectService.getProjects();

      final currentOpenId = state.openProjectId;
      final openStillValid =
          currentOpenId == 'default' || _projectExists(currentOpenId, projects);

      state = state.copyWith(
        isLoading: false,
        projects: projects,
        openProjectId: openStillValid ? currentOpenId : 'default',
      );
    } catch (e) {
      _setError(e);
    }
  }

  void openProject(String projectId) {
    if (projectId != 'default') {
      final exists = state.projects.any((p) => p.id == projectId);
      if (!exists) return;
    }

    state = state.copyWith(
      openProjectId: projectId,
      videos: const [],
      clearSelectedVideoId: true,
      clearError: true,
    );
  }


  void openDefaultProject() => openProject('default');

  Future<void> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    if (_projectNameExists(trimmed)) {
      state = state.copyWith(
        errorMessage: 'A project with this name already exists',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final created = await _projectService.createProject(trimmed);

      state = state.copyWith(
        isLoading: false,
        projects: [...state.projects, created],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }


  void enterSelectionMode({String? initialProjectId}) {
    // default can't be selected
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
    if (projectId == 'default') return;

    final next = Set<String>.from(state.selectedProjectIds);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }

    final shouldExit = next.isEmpty;

    state = state.copyWith(
      isSelectionMode: shouldExit ? false : true,
      selectedProjectIds: next,
      clearError: true,
    );
  }

  Future<void> renameProject(String projectId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

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
      );
    } catch (e) {
      _setError(e);
    }
  }


  Future<void> deleteProject(String projectId) async {
    _setLoading(true);
    try {
      await _projectService.deleteProject(projectId);

      final updated = state.projects.where((p) => p.id != projectId).toList();

      final newOpenId =
      state.openProjectId == projectId ? 'default' : state.openProjectId;

      state = state.copyWith(
        isLoading: false,
        projects: updated,
        openProjectId: newOpenId,
      );
    } catch (e) {
      _setError(e);
    }
  }

  void handleProjectTap(String projectId) {
    if (state.isSelectionMode) {
      toggleProjectSelection(projectId);
      return;
    }
    openProject(projectId);
  }

  void handleProjectLongPress(String projectId) {
    if (projectId == 'default') return;
    if (!state.isSelectionMode) {
      enterSelectionMode(initialProjectId: projectId);
    }
  }

  void duplicateProject(String projectId) {
    final project = state.projects.firstWhere((p) => p.id == projectId, orElse: () => throw StateError('Project not found'));
    final duplicateName = '${project.name} (Copy)';

    createProject(duplicateName);
  }


}
