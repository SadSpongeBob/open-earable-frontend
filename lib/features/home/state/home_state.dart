import 'package:flutter/foundation.dart';
import '../../../api/models/project.dart';
import '../../../api/models/video.dart';

@immutable
class HomeState {
  final List<Project> projects;

  final String openProjectId;

  final bool isSelectionMode;
  final Set<String> selectedProjectIds;

  final List<Video> videos;
  final String? selectedVideoId;

  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    required this.projects,
    required this.openProjectId,
    required this.isSelectionMode,
    required this.selectedProjectIds,
    required this.videos,
    required this.selectedVideoId,
    required this.isLoading,
    required this.errorMessage,
  });

  factory HomeState.initial() => const HomeState(
    projects: [],
    openProjectId: 'default',
    isSelectionMode: false,
    selectedProjectIds: {},
    videos: [],
    selectedVideoId: null,
    isLoading: false,
    errorMessage: null,
  );

  HomeState copyWith({
    List<Project>? projects,
    String? openProjectId,
    bool? isSelectionMode,
    Set<String>? selectedProjectIds,
    List<Video>? videos,
    String? selectedVideoId,
    bool clearSelectedVideoId = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
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
    );
  }
}
