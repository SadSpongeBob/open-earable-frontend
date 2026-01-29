import 'package:flutter/foundation.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/recording/recording.dart';

@immutable
class Project {
  final String id;
  final String name;

  final String ownerId;
  final List<Recording> recordings;
  final List<ProjectRole> users;

  const Project({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.recordings,
    required this.users,
  });

  bool isOwner(String userId) => ownerId == userId;

  bool isEditor(String userId) =>
      users.any((u) => u.userId == userId && u.canEditVideos());

  bool isViewer(String userId) =>
      users.any((u) => u.userId == userId && u.canViewVideos());

  factory Project.fromJson(Map<String, dynamic> json) {
    final id = json['projectId'] as String;
    final name = json['name'] as String;

    final ownerId = json['ownerId'] as String;

    final users = json['users'] as List;
    final projectUsers = users
        .map((user) => ProjectRole.fromJson(user))
        .toList();

    final recordings = (json['recordings'] as List)
        .map((r) => Recording.fromJson(r))
        .toList();

    return Project(
      id: id,
      name: name,
      ownerId: ownerId,
      recordings: recordings,
      users: projectUsers,
    );
  }

  Project copyWith({String? name}) {
    return Project(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      recordings: recordings,
      users: users,
    );
  }

  ProjectMetadata toMetadata() {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: recordings.length,
      userAmount: users.length,
      projectSource: ProjectSource.cloud,
    );
  }
}
