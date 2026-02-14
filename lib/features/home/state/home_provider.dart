import 'package:flutter_riverpod/legacy.dart';

import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import '../../../api/models/project/project_user.dart';
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

  // Projects selection
  void setProjectSelection(Set<String> ids) {
    state = state.copyWith(
      selectedProjectIds: ids,
      isProjectSelectionMode: ids.isNotEmpty,
    );
  }

  void clearProjectSelection() {
    state = state.copyWith(
      selectedProjectIds: const <String>{},
      isProjectSelectionMode: false,
    );
  }

  // Recordings selection
  void setRecordingSelection(Set<String> ids) {
    state = state.copyWith(
      selectedRecordingIds: ids,
      isRecordingSelectionMode: ids.isNotEmpty,
    );
  }

  void clearRecordingSelection() {
    state = state.copyWith(
      selectedRecordingIds: const <String>{},
      isRecordingSelectionMode: false,
    );
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
    required List<Recording> recordings,
  }) {
    state = state.copyWith(
      openProjectId: projectId,
      recordings: recordings,
      clearSelectedRecordingId: true,
      clearError: true,
      isRecordingSelectionMode: false,
      selectedRecordingIds: const <String>{},
    );
  }

  // ----------------
  // Projects list ops
  // ----------------

  void addProject(ProjectMetadata project) {
    state = state.copyWith(
      projects: [...state.projects, project],
      clearError: true,
    );
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
      isProjectSelectionMode: nextSelected.isNotEmpty,
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
    state = state.copyWith(isUsersLoading: false, usersErrorMessage: message);
  }

  void clearUsersPopupState() {
    state = state.copyWith(
      isUsersLoading: false,
      clearUsersError: true,
      clearProjectUsers: true,
      usersErrorMessage: null,
    );
  }

  // ----------------
  // Recordings
  // ----------------

  void addRecording(Recording recording) {
    state = state.copyWith(recordings: [recording, ...state.recordings]);
  }

  void updateRecording({
    required String id,
    String? newName,
    UploadStatus? uploadStatus,
  }) {
    state = state.copyWith(
      recordings: [
        for (final recording in state.recordings)
          if (recording.id == id)
            recording.copyWith(name: newName, uploadStatus: uploadStatus)
          else
            recording,
      ],
    );
  }

  void removeRecording(String id) {
    final updated = state.recordings.where((r) => !(r.id == id)).toList();

    final shouldClearSelected =
        state.selectedRecordingId != null && state.selectedRecordingId == id;

    state = state.copyWith(
      recordings: updated,
      selectedRecordingId: shouldClearSelected ? null : state.selectedRecordingId,
    );
  }
}
