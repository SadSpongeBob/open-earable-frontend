import 'package:flutter/foundation.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';

@immutable
class Project {
  final String id;
  final String name;

  final String ownerId;
  final List<Recording> recordings;
  final List<ProjectUser> users;

  const Project({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.recordings,
    required this.users,
  });

  bool isOwner(String userId) => ownerId == userId;

  bool isEditor(String userId) =>
      users.any((u) => u.userId == userId && u.role == ProjectRole.editor);

  bool isViewer(String userId) =>
      users.any((u) => u.userId == userId && u.role == ProjectRole.viewer);

  factory Project.fromJson(Map<String, dynamic> json) {
    final id = json['projectId'] as String;
    final name = json['name'] as String;

    final ownerId = json['ownerId'] as String;

    final users = json['users'] as List;
    final projectUsers = users
        .map((user) => ProjectUser.fromJson(user))
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
    );
  }
}

class ProjectUser {
  final String userId;
  final ProjectRole role;

  const ProjectUser({required this.userId, required this.role});

  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final role = ProjectRole.fromString(json['role'] as String);

    return ProjectUser(userId: userId, role: role);
  }
}

enum ProjectRole {
  owner,
  editor,
  viewer;

  factory ProjectRole.fromString(String value) {
    return switch (value) {
      'OWNER' => ProjectRole.owner,
      'EDITOR' => ProjectRole.editor,
      'VIEWER' => ProjectRole.viewer,
      _ => throw ArgumentError.value(value, 'value', 'Invalid ProjectRole'),
    };
  }
}
