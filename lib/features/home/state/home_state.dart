import 'package:flutter/foundation.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_user.dart';
import '../../../api/models/recording/recording.dart';

@immutable
class HomeState {
  final List<ProjectMetadata> projects;

  final String openProjectId;
  final Project? openProject;

  final bool isSelectionMode;
  final Set<String> selectedProjectIds;

  final List<Recording> videos;
  final String? selectedVideoId;

  final bool isLoading;
  final String? errorMessage;

  final bool isUsersLoading;
  final List<ProjectUser> projectUsers;
  final String? usersErrorMessage;

  const HomeState({
    required this.projects,
    required this.openProjectId,
    required this.openProject,
    required this.isSelectionMode,
    required this.selectedProjectIds,
    required this.videos,
    required this.selectedVideoId,
    required this.isLoading,
    required this.errorMessage,
    required this.isUsersLoading,
    required this.projectUsers,
    required this.usersErrorMessage,
  });

  factory HomeState.initial() => const HomeState(
    projects: [],
    openProjectId: 'default',
    openProject: null,
    isSelectionMode: false,
    selectedProjectIds: {},
    videos: [],
    selectedVideoId: null,
    isLoading: false,
    errorMessage: null,
    isUsersLoading: false,
    projectUsers: [],
    usersErrorMessage: null,
  );

  HomeState copyWith({
    List<ProjectMetadata>? projects,
    String? openProjectId,
    Project? openProject,
    bool clearOpenProject = false,

    bool? isSelectionMode,
    Set<String>? selectedProjectIds,

    List<Recording>? videos,
    String? selectedVideoId,
    bool clearSelectedVideoId = false,

    bool? isLoading,
    String? errorMessage,
    bool clearError = false,

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

      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedProjectIds: selectedProjectIds ?? this.selectedProjectIds,

      videos: videos ?? this.videos,
      selectedVideoId:
      clearSelectedVideoId ? null : (selectedVideoId ?? this.selectedVideoId),

      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

      isUsersLoading: isUsersLoading ?? this.isUsersLoading,
      projectUsers: clearProjectUsers ? const [] : (projectUsers ?? this.projectUsers),
      usersErrorMessage:
      clearUsersError ? null : (usersErrorMessage ?? this.usersErrorMessage),
    );
  }
}
