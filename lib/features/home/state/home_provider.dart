import 'package:flutter_riverpod/legacy.dart';

import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import '../../../api/models/project/project_user.dart';
import '../state/home_state.dart';

final homeStateProvider =
StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
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

  void clearSelection() {
    state = state.copyWith(selectedProjectIds: {}, isSelectionMode: false);
  }

  void setProjectsLoaded(bool loaded) =>
      state = state.copyWith(areProjectsLoaded: loaded);

  void setLoading(bool value) => state = state.copyWith(isLoading: value);

  void setErrorMessage(String? message) =>
      state = state.copyWith(isLoading: false, errorMessage: message);

  void clearError() => state = state.copyWith(clearError: true);

  void setProjects(List<ProjectMetadata> projects) =>
      state = state.copyWith(projects: projects);

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
    state = state.copyWith(projects: [...state.projects, project], clearError: true);
  }

  void renameProjectInList(String projectId, String newName) {
    final updated = state.projects.map((p) {
      if (p.id != projectId) return p;
      return p.copyWith(name: newName);
    }).toList();

    state = state.copyWith(projects: updated);
  }

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

  // ----------------
  // Project users popup setters
  // ----------------

  void setUsersLoading(bool value) {
    state = state.copyWith(isUsersLoading: value, clearUsersError: true);
  }

  void setProjectUsers(List<ProjectUser> users) {
    state = state.copyWith(
      isUsersLoading: false,
      projectUsers: users,
      usersErrorMessage: null,
    );
  }


  void setUsersError(String message) {
    state = state.copyWith(
      isUsersLoading: false,
      usersErrorMessage: message,
    );
  }

  void clearUsersPopupState() {
    state = state.copyWith(
      isUsersLoading: false,
      clearUsersError: true,
      clearProjectUsers: true,
      usersErrorMessage: null,
    );
  }
}
