import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import '../state/home_state.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>((
  ref,
) {
  return HomeStateNotifier();
});

class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier() : super(HomeState.initial());

  HomeState get current => state;

  // ----------------
  // Generic setters
  // ----------------

  void setSelection(Set<String> ids) {
    state = state.copyWith(
      selectedProjectIds: ids,
      isSelectionMode: ids.isNotEmpty,
    );
  }

  void setProjectsLoaded(bool loaded) {
    state = state.copyWith(areProjectsLoaded: loaded);
  }

  void clearSelection() {
    state = state.copyWith(selectedProjectIds: {}, isSelectionMode: false);
  }

  void setLoading(bool value) => state = state.copyWith(isLoading: value);

  void setErrorMessage(String? message) =>
      state = state.copyWith(isLoading: false, errorMessage: message);

  void clearError() => state = state.copyWith(clearError: true);

  void setProjects(List<ProjectMetadata> projects) =>
      state = state.copyWith(projects: projects);

  void setOpenProjectId(String projectId) =>
      state = state.copyWith(openProjectId: projectId);

  void setVideos(List<Recording> videos, {bool clearSelected = true}) {
    state = state.copyWith(videos: videos, clearSelectedVideoId: clearSelected);
  }

  void setOpenProject({
    required String projectId,
    required List<Recording> videos,
  }) {
    state = state.copyWith(
      openProjectId: projectId,
      videos: videos,
      clearSelectedVideoId: true,
      clearError: true,
    );
  }

  // ----------------
  // Projects list ops
  // ----------------

  void addProject(ProjectMetadata project) {
    state = state.copyWith(
        projects: [...state.projects, project], clearError: true);
  }

  void renameProjectInList(String projectId, String newName) {
    final updated = state.projects.map((p) {
      if (p.id != projectId) return p;
      return p.copyWith(name: newName);
    }).toList();

    state = state.copyWith(projects: updated);
  }

  /// Removes project from list + also cleans selection set.
  void removeProject(String projectId) {
    final updated = state.projects.where((p) => p.id != projectId).toList();

    final nextSelected = Set<String>.from(state.selectedProjectIds)
      ..remove(projectId);

    state = state.copyWith(
      projects: updated,
      selectedProjectIds: nextSelected,
      isSelectionMode: nextSelected.isNotEmpty,
      clearError: true,
    );
  }
}
