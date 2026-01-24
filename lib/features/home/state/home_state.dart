import 'package:flutter/foundation.dart';
import '../../../api/models/auth/user.dart';
import '../../../api/models/project.dart';
import '../../../api/models/video.dart';

@immutable
class HomeState {
  // projects
  final List<Project> projects;
  final String? openProjectId;

  // selection
  final bool isSelectionMode;
  final Set<String> selectedProjectIds;

  // videos
  final List<Video> videos;
  final String? selectedVideoId;

  // general loading / error
  final bool isLoading;
  final String? errorMessage;

  // users popup
  final bool isUsersLoading;
  final List<ProjectUserEntry> projectUsers;

  final String usersEmailInput;
  final ProjectRole usersSelectedRole;

  final ProjectRole? myProjectRole;
  final String? usersErrorMessage;

  const HomeState({
    required this.projects,
    required this.openProjectId,
    required this.isSelectionMode,
    required this.selectedProjectIds,
    required this.videos,
    required this.selectedVideoId,
    required this.isLoading,
    required this.errorMessage,
    required this.isUsersLoading,
    required this.projectUsers,
    required this.usersEmailInput,
    required this.usersSelectedRole,
    required this.myProjectRole,
    required this.usersErrorMessage,
  });

  factory HomeState.initial() => const HomeState(
    projects: [],
    openProjectId: null,
    isSelectionMode: false,
    selectedProjectIds: {},
    videos: [],
    selectedVideoId: null,
    isLoading: false,
    errorMessage: null,
    isUsersLoading: false,
    projectUsers: [],
    usersEmailInput: '',
    usersSelectedRole: ProjectRole.viewer,
    myProjectRole: null,
    usersErrorMessage: null,
  );

  HomeState copyWith({
    // projects
    List<Project>? projects,
    String? openProjectId,

    // selection
    bool? isSelectionMode,
    Set<String>? selectedProjectIds,

    // videos
    List<Video>? videos,
    String? selectedVideoId,
    bool clearSelectedVideoId = false,

    // general loading / error
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,

    // users popup
    bool? isUsersLoading,
    List<ProjectUserEntry>? projectUsers,
    String? usersEmailInput,
    ProjectRole? usersSelectedRole,
    ProjectRole? myProjectRole,
    String? usersErrorMessage,
    bool clearUsersError = false,
  }) {
    return HomeState(
      projects: projects ?? this.projects,
      openProjectId: openProjectId ?? this.openProjectId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedProjectIds: selectedProjectIds ?? this.selectedProjectIds,
      videos: videos ?? this.videos,
      selectedVideoId:
      clearSelectedVideoId ? null : (selectedVideoId ?? this.selectedVideoId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

      isUsersLoading: isUsersLoading ?? this.isUsersLoading,
      projectUsers: projectUsers ?? this.projectUsers,
      usersEmailInput: usersEmailInput ?? this.usersEmailInput,
      usersSelectedRole: usersSelectedRole ?? this.usersSelectedRole,
      myProjectRole: myProjectRole ?? this.myProjectRole,
      usersErrorMessage:
      clearUsersError ? null : (usersErrorMessage ?? this.usersErrorMessage),
    );
  }
}

