import 'package:flutter/foundation.dart';

import 'auth/user.dart';

@immutable
abstract class ProjectRole {
  final User user;

  const ProjectRole({required this.user});

  String getRoleName();

  bool canViewVideos();
  bool canEditVideos();
  bool canRecord();
  bool canManageUsers();

  static ProjectRole fromRoleName({
    required String roleName,
    required User user,
  }) {
    switch (roleName.toLowerCase()) {
      case 'owner':
        return Owner(user: user);
      case 'editor':
        return Editor(user: user);
      case 'viewer':
        return Viewer(user: user);
      default:
        throw ArgumentError('Unknown roleName: $roleName');
    }
  }
}

class Owner extends ProjectRole {
  const Owner({required super.user});

  @override
  String getRoleName() => 'owner';

  @override
  bool canViewVideos() => true;

  @override
  bool canEditVideos() => true;

  @override
  bool canRecord() => true;

  @override
  bool canManageUsers() => true;
}

class Editor extends ProjectRole {
  const Editor({required super.user});

  @override
  String getRoleName() => 'editor';

  @override
  bool canViewVideos() => true;

  @override
  bool canEditVideos() => true;

  @override
  bool canRecord() => true;

  @override
  bool canManageUsers() => false;
}

class Viewer extends ProjectRole {
  const Viewer({required super.user});

  @override
  String getRoleName() => 'viewer';

  @override
  bool canViewVideos() => true;

  @override
  bool canEditVideos() => false;

  @override
  bool canRecord() => false;

  @override
  bool canManageUsers() => false;
}
