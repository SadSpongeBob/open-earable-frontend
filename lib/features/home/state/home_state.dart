import 'package:flutter/foundation.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_user.dart';
import '../../../api/models/recording/recording.dart';

/// Represents the state of the home page, including:
/// 
/// - The list of projects and the currently open project
/// - Selection state for projects and recordings
/// - Recordings in the open project
/// - Loading and error states
/// - Users in the currently open project (for the users popup)
///
/// This state is immutable and updated via `HomeStateNotifier`.
@immutable
class HomeState {
  final List<ProjectMetadata> projects;

  final String openProjectId;
  final Project? openProject;

  // Project selection
  final bool isProjectSelectionMode;
  final Set<String> selectedProjectIds;

  // Recording selection
  final bool isRecordingSelectionMode;
  final Set<String> selectedRecordingIds;
  final List<Recording> recordings;
  final String? selectedRecordingId;

  // UI state
  final bool isLoading;
  final String? errorMessage;
  final bool areProjectsLoaded;

  // Users popup
  final bool isUsersLoading;
  final List<ProjectUser> projectUsers;
  final String? usersErrorMessage;

  const HomeState({
    required this.projects,
    required this.openProjectId,
    required this.openProject,
    required this.isProjectSelectionMode,
    required this.selectedProjectIds,
    required this.isRecordingSelectionMode,
    required this.selectedRecordingIds,
    required this.recordings,
    required this.selectedRecordingId,
    required this.isLoading,
    required this.errorMessage,
    required this.areProjectsLoaded,
    required this.isUsersLoading,
    required this.projectUsers,
    required this.usersErrorMessage,
  });

  /// Returns the initial/default state for the home page.
  /// 
  /// - Contains a single default project.
  /// - No project or recording is selected.
  /// - Loading flags are false.
  /// - Error messages are null.
  factory HomeState.initial() => HomeState(
    projects: [
      ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
    ],
    openProjectId: LocalMedia.defaultProjectId,
    openProject: null,
    isProjectSelectionMode: false,
    selectedProjectIds: const <String>{},
    isRecordingSelectionMode: false,
    selectedRecordingIds: const <String>{},
    recordings: const [],
    selectedRecordingId: null,
    isLoading: false,
    errorMessage: null,
    areProjectsLoaded: false,
    isUsersLoading: false,
    projectUsers: const [],
    usersErrorMessage: null,
  );

  HomeState copyWith({
    List<ProjectMetadata>? projects,
    String? openProjectId,
    Project? openProject,
    bool clearOpenProject = false,

    bool? isProjectSelectionMode,
    Set<String>? selectedProjectIds,

    bool? isRecordingSelectionMode,
    Set<String>? selectedRecordingIds,
    List<Recording>? recordings,
    String? selectedRecordingId,
    bool clearSelectedRecordingId = false,

    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? areProjectsLoaded,

    bool? isUsersLoading,
    List<ProjectUser>? projectUsers,
    String? usersErrorMessage,
    bool clearUsersError = false,
    bool clearProjectUsers = false,
  }) {
    return HomeState(
      projects: projects ?? this.projects,
      openProjectId: openProjectId ?? this.openProjectId,
      openProject: clearOpenProject ? null : (openProject ?? this.openProject),

      isProjectSelectionMode:
      isProjectSelectionMode ?? this.isProjectSelectionMode,
      selectedProjectIds: selectedProjectIds ?? this.selectedProjectIds,

      isRecordingSelectionMode:
      isRecordingSelectionMode ?? this.isRecordingSelectionMode,
      selectedRecordingIds: selectedRecordingIds ?? this.selectedRecordingIds,
      recordings: recordings ?? this.recordings,
      selectedRecordingId: clearSelectedRecordingId
          ? null
          : (selectedRecordingId ?? this.selectedRecordingId),

      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      areProjectsLoaded: areProjectsLoaded ?? this.areProjectsLoaded,

      isUsersLoading: isUsersLoading ?? this.isUsersLoading,
      projectUsers: clearProjectUsers ? const [] : (projectUsers ?? this.projectUsers),
      usersErrorMessage:
      clearUsersError ? null : (usersErrorMessage ?? this.usersErrorMessage),
    );
  }
}