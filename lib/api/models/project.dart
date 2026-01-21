import 'package:openearable/api/models/project_role.dart';
import 'package:openearable/api/models/video.dart';
import 'auth/user.dart';
import 'package:flutter/foundation.dart';

@immutable
class Project {
  final String id;
  final String name;

  final Owner owner;
  final List<Video> videos;
  final List<Viewer> viewers;
  final List<Editor> editors;

  const Project({
    required this.id,
    required this.name,
    required this.owner,
    required this.videos,
    required this.viewers,
    required this.editors,
  });

  bool isOwner(String userId) => owner.user.userId == userId;

  bool isEditor(String userId) => editors.any((r) => r.user.userId == userId);

  bool isViewer(String userId) => viewers.any((r) => r.user.userId == userId);

  ProjectRole? getRoleOfUser(String userId) {
    if (isOwner(userId)) return owner;
    final e = editors.where((r) => r.user.userId == userId);
    if (e.isNotEmpty) return e.first;
    final v = viewers.where((r) => r.user.userId == userId);
    if (v.isNotEmpty) return v.first;
    return null;
  }

  List<User> getAllUsers() {
    final map = <String, User>{};
    map[owner.user.userId] = owner.user;
    for (final r in editors) map[r.user.userId] = r.user;
    for (final r in viewers) map[r.user.userId] = r.user;
    return map.values.toList();
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String? ?? '';

    Owner ownerRole = _parseOwner(json['owner']);
    final videos = (json['videos'] as List<dynamic>? ?? const [])
        .map((e) => Video.fromJson(e as Map<String, dynamic>))
        .toList();

    final viewers = _parseRoleList(
      json['viewers'],
      expectedRoleName: 'viewer',
      builder: (u) => Viewer(user: u),
    );

    final editors = _parseRoleList(
      json['editors'],
      expectedRoleName: 'editor',
      builder: (u) => Editor(user: u),
    );

    return Project(
      id: id,
      name: name,
      owner: ownerRole,
      videos: videos,
      viewers: viewers,
      editors: editors,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner': {
      'role': owner.getRoleName(),
      'user': owner.user.toJson(),
    },
    'videos': videos.map((v) => v.toJson()).toList(),
    'viewers': viewers
        .map((r) => {'role': r.getRoleName(), 'user': r.user.toJson()})
        .toList(),
    'editors': editors
        .map((r) => {'role': r.getRoleName(), 'user': r.user.toJson()})
        .toList(),
  };

  static Owner _parseOwner(dynamic raw) {
    if (raw == null) {
      throw StateError('Project.owner is missing');
    }

    // Case A: owner is a plain user object
    if (raw is Map<String, dynamic> && raw.containsKey('id')) {
      return Owner(user: User.fromJson(raw));
    }

    // Case B: owner is { user: {...}, role: "owner" }
    if (raw is Map<String, dynamic> && raw['user'] is Map<String, dynamic>) {
      final user = User.fromJson(raw['user'] as Map<String, dynamic>);
      return Owner(user: user);
    }

    throw StateError('Unsupported owner format: ${raw.runtimeType}');
  }

  static List<T> _parseRoleList<T extends ProjectRole>(
      dynamic raw, {
        required String expectedRoleName,
        required T Function(User user) builder,
      }) {
    final list = (raw as List<dynamic>? ?? const []);

    return list.map((e) {
      // Case A: plain user
      if (e is Map<String, dynamic> && e.containsKey('id')) {
        return builder(User.fromJson(e));
      }

      // Case B: { user: {...}, role: "viewer"/"editor" }
      if (e is Map<String, dynamic> && e['user'] is Map<String, dynamic>) {
        final user = User.fromJson(e['user'] as Map<String, dynamic>);
        final role = (e['role'] as String?)?.toLowerCase();
        if (role != null && role != expectedRoleName) {
          throw StateError('Expected role=$expectedRoleName but got $role');
        }
        return builder(user);
      }

      throw StateError('Unsupported role entry format: ${e.runtimeType}');
    }).toList();
  }
}

