enum ProjectRoleType { owner, editor, viewer }

extension ProjectRoleTypeApi on ProjectRoleType {
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

class Viewer extends ProjectRole {
  Viewer({required super.userId});
}

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

extension ProjectRoleApi on ProjectRole {
  String toApi() {
    if (this is Owner) return 'OWNER';
    if (this is Editor) return 'EDITOR';
    return 'VIEWER';
  }

  String get label {
    if (this is Owner) return 'Owner';
    if (this is Editor) return 'Editor';
    return 'Viewer';
  }
}
