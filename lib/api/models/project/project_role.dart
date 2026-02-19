/// Represents the type of role a user can have in a project.
enum ProjectRoleType { owner, editor, viewer }

/// Provides API serialization and user-friendly labels for [ProjectRoleType].
extension ProjectRoleTypeApi on ProjectRoleType {
  /// Converts the role to the uppercase string used in API requests/responses.
  String toApi() {
    switch (this) {
      case ProjectRoleType.owner:
        return 'OWNER';
      case ProjectRoleType.editor:
        return 'EDITOR';
      case ProjectRoleType.viewer:
        return 'VIEWER';
    }
  }

  /// Returns a human-readable label for the role.
  String get label {
    switch (this) {
      case ProjectRoleType.owner:
        return 'Owner';
      case ProjectRoleType.editor:
        return 'Editor';
      case ProjectRoleType.viewer:
        return 'Viewer';
    }
  }

  /// Creates a [ProjectRoleType] from an API string value.
  /// 
  /// Throws [ArgumentError] if the role string is invalid.
  static ProjectRoleType fromApi(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return ProjectRoleType.owner;
      case 'EDITOR':
        return ProjectRoleType.editor;
      case 'VIEWER':
        return ProjectRoleType.viewer;
      default:
        throw ArgumentError.value(role, 'role', 'Invalid role');
    }
  }
}

/// Represents a user's role within a project, including permissions.
/// 
/// Parameters:
/// - [userId]: The ID of the user associated with this role.
abstract class ProjectRole {
  final String userId;

  const ProjectRole({required this.userId});

  bool canViewVideos() => true;

  bool canEditVideos() => false;

  bool canRecord() => false;

  bool canManageUsers() => false;

  factory ProjectRole.fromApi({
    required String userId,
    required String role,
  }) {
    return switch (ProjectRoleTypeApi.fromApi(role)) {
      ProjectRoleType.owner => Owner(userId: userId),
      ProjectRoleType.editor => Editor(userId: userId),
      ProjectRoleType.viewer => Viewer(userId: userId),
    };
  }


  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final role = json['role'] as String;
    return ProjectRole.fromApi(userId: userId, role: role);
  }
}

/// Viewer role: read-only access to project recordings.
class Viewer extends ProjectRole {
  Viewer({required super.userId});
}

/// Editor role: can view, edit, and record videos but cannot manage users.
class Editor extends ProjectRole {
  Editor({required super.userId});

  @override
  bool canEditVideos() {
    return true;
  }

  @override
  bool canRecord() {
    return true;
  }
}

/// Owner role: full permissions including managing users and recordings.
class Owner extends ProjectRole {
  Owner({required super.userId});

  @override
  bool canEditVideos() {
    return true;
  }

  @override
  bool canManageUsers() {
    return true;
  }

  @override
  bool canRecord() {
    return true;
  }
}

/// Provides API serialization and human-readable labels for [ProjectRole] instances.
extension ProjectRoleApi on ProjectRole {
  /// Returns the API string representation of this role (OWNER, EDITOR, VIEWER).
  String toApi() {
    if (this is Owner) return 'OWNER';
    if (this is Editor) return 'EDITOR';
    return 'VIEWER';
  }

  /// Returns a human-readable label for this role.
  String get label {
    if (this is Owner) return 'Owner';
    if (this is Editor) return 'Editor';
    return 'Viewer';
  }
}
