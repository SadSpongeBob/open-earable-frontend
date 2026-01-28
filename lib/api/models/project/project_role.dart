abstract class ProjectRole {
  final String userId;

  const ProjectRole({required this.userId});

  bool canViewVideos() {
    return true;
  }

  bool canEditVideos() {
    return false;
  }

  bool canRecord() {
    return false;
  }

  bool canManageUsers() {
    return false;
  }

  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final role = json['role'] as String;

    return switch (role) {
      'OWNER' => Owner(userId: userId),
      'EDITOR' => Editor(userId: userId),
      'VIEWER' => Viewer(userId: userId),
      _ => throw ArgumentError.value(role, 'role', 'Invalid ProjectRole'),
    };
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