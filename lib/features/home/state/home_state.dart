import 'package:flutter/foundation.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import '../../../api/models/recording/recording.dart';

@immutable
class HomeState {
  final List<ProjectMetadata> projects;

  final String openProjectId;

  final bool isSelectionMode;
  final Set<String> selectedProjectIds;

  final List<Recording> videos;
  final String? selectedVideoId;

  final bool isLoading;
  final String? errorMessage;
  final bool areProjectsLoaded;

  const HomeState({
    required this.projects,
    required this.openProjectId,
    required this.isSelectionMode,
    required this.selectedProjectIds,
    required this.videos,
    required this.selectedVideoId,
    required this.isLoading,
    required this.errorMessage,
    required this.areProjectsLoaded,
  });

  factory HomeState.initial() => HomeState(
    projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
    openProjectId: LocalMedia.defaultProjectId,
    isSelectionMode: false,
    selectedProjectIds: {},
    videos: [],
    selectedVideoId: null,
    isLoading: false,
    errorMessage: null,
    areProjectsLoaded: false,
  );

  HomeState copyWith({
    List<ProjectMetadata>? projects,
    String? openProjectId,
    bool? isSelectionMode,
    Set<String>? selectedProjectIds,
    List<Recording>? videos,
    String? selectedVideoId,
    bool clearSelectedVideoId = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? areProjectsLoaded,
  }) {
    return HomeState(
      projects: projects ?? this.projects,
      openProjectId: openProjectId ?? this.openProjectId,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedProjectIds: selectedProjectIds ?? this.selectedProjectIds,
      videos: videos ?? this.videos,
      selectedVideoId: clearSelectedVideoId
          ? null
          : (selectedVideoId ?? this.selectedVideoId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      areProjectsLoaded: areProjectsLoaded ?? this.areProjectsLoaded,
    );
  }
}
