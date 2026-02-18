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

/// [HomeStateNotifier] manages the state of the home page, including:
/// - The list of projects and the currently open project
/// - Project and recording selection for batch operations
/// - Users in a project (for the users popup)
/// - Loading and error states
/// - Recordings and their updates
///
/// This notifier is used by the [homeStateProvider] to update the UI
/// reactively via Riverpod.
class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier() : super(HomeState.initial());

  HomeState get current => state;

  // ------------------------------------------------------------
  // Generic setters
  // ------------------------------------------------------------

  /// Sets the selected project IDs and enables project selection mode.
  void setProjectSelection(Set<String> ids) {
    state = state.copyWith(
      selectedProjectIds: ids,
      isProjectSelectionMode: ids.isNotEmpty,
    );
  }

  /// Clears project selection and disables project selection mode.
  void clearProjectSelection() {
    state = state.copyWith(
      selectedProjectIds: const <String>{},
      isProjectSelectionMode: false,
    );
  }

  /// Sets the selected recording IDs and enables recording selection mode.
  void setRecordingSelection(Set<String> ids) {
    state = state.copyWith(
      selectedRecordingIds: ids,
      isRecordingSelectionMode: ids.isNotEmpty,
    );
  }

  /// Clears recording selection and disables recording selection mode.
  void clearRecordingSelection() {
    state = state.copyWith(
      selectedRecordingIds: const <String>{},
      isRecordingSelectionMode: false,
    );
  }

  /// Marks whether projects are loaded.
  void setProjectsLoaded(bool loaded) =>
      state = state.copyWith(areProjectsLoaded: loaded);

  /// Sets the global loading flag.
  void setLoading(bool value) => state = state.copyWith(isLoading: value);

  /// Sets an error message and clears the loading state.
  void setErrorMessage(String? message) =>
      state = state.copyWith(isLoading: false, errorMessage: message);

  /// Clears the current error state.
  void clearError() => state = state.copyWith(clearError: true);

  /// Replaces the current list of projects.
  void setProjects(List<ProjectMetadata> projects) =>
      state = state.copyWith(projects: projects);

  /// Sets the currently open project and its recordings.
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

  // ------------------------------------------------------------
  // Projects list ops
  // ------------------------------------------------------------

  /// Adds a project to the current list.
  void addProject(ProjectMetadata project) {
    state = state.copyWith(
      projects: [...state.projects, project],
      clearError: true,
    );
  }

  /// Renames a project in the current list.
  void renameProjectInList(String projectId, String newName) {
    final updated = state.projects.map((p) {
      if (p.id != projectId) return p;
      return p.copyWith(name: newName);
    }).toList();

    state = state.copyWith(projects: updated);
  }

  /// Removes a project from the list and clears it from selection if necessary.
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

  // ------------------------------------------------------------
  // Project users popup setters
  // ------------------------------------------------------------

  /// Sets the loading state for the users popup.
  void setUsersLoading(bool value) {
    state = state.copyWith(isUsersLoading: value, clearUsersError: true);
  }

  /// Sets the list of users for the currently open project.
  void setProjectUsers(List<ProjectUser> users) {
    state = state.copyWith(
      isUsersLoading: false,
      projectUsers: users,
      usersErrorMessage: null,
    );
  }

  /// Sets an error message for the users popup.
  void setUsersError(String message) {
    state = state.copyWith(isUsersLoading: false, usersErrorMessage: message);
  }

  /// Clears the users popup state including errors and selection.
  void clearUsersPopupState() {
    state = state.copyWith(
      isUsersLoading: false,
      clearUsersError: true,
      clearProjectUsers: true,
      usersErrorMessage: null,
    );
  }

  // ------------------------------------------------------------
  // Recordings
  // ------------------------------------------------------------

  /// Adds a recording to the top of the list.
  void addRecording(Recording recording) {
    state = state.copyWith(recordings: [recording, ...state.recordings]);
  }

  /// Updates an existing recording's name or upload status.
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

  /// Replaces an existing recording with a new one, updating selection if needed.
  void replaceRecording({
    required String oldId,
    required Recording newRecording,
  }) {
    final updated = [
      for (final recording in state.recordings)
        if (recording.id == oldId) newRecording else recording,
    ];

    final nextSelected = Set<String>.from(state.selectedRecordingIds)
      ..remove(oldId)
      ..add(newRecording.id);

    final shouldClearSelected =
        state.selectedRecordingId != null && state.selectedRecordingId == oldId;

    state = state.copyWith(
      recordings: updated,
      selectedRecordingId: shouldClearSelected
          ? newRecording.id
          : state.selectedRecordingId,
      selectedRecordingIds: nextSelected,
    );
  }

  /// Removes a recording from the list and clears selection if it was selected.
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
