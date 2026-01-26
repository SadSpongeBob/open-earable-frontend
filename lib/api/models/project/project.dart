import 'package:flutter/foundation.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/recording/video.dart';
import '../auth/user.dart';

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
    for (final r in editors) {
      map[r.user.userId] = r.user;
    }
    for (final r in viewers) {
      map[r.user.userId] = r.user;
    }
    return map.values.toList();
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final id = json['projectId'] as String;
    final name = json['name'] as String;


    final ownerId = json['ownerId'] as String;
    final ownerUser = _placeholderUser(ownerId);
    final ownerRole = Owner(user: ownerUser);


    final userIdsRaw = json['userIds'];
    final userIds = (userIdsRaw is List)
        ? userIdsRaw.whereType<String>().toList()
        : <String>[];


    final viewers = userIds
        .where((u) => u.isNotEmpty && u != ownerId)
        .map((u) => Viewer(user: _placeholderUser(u)))
        .toList();

    // TODO: Implement proper editor/viewer distinction when API supports it
    const editors = <Editor>[];


    final recordingsRaw = json['recordings'];
    final videos = <Video>[];
    if (recordingsRaw is List) {
      for (final e in recordingsRaw) {
        if (e is Map<String, dynamic>) {
          try {
            videos.add(Video.fromJson(e));
          } catch (_) {
          }
        }
      }
    }

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
    'projectId': id,
    'name': name,
    'ownerId': owner.user.userId,
    'userIds': getAllUsers().map((u) => u.userId).toSet().toList(),
    'recordings': videos.map((v) => v.toJson()).toList(),
  };

  Project copyWith({
    String? name,
    Owner? owner,
    List<Video>? videos,
    List<Editor>? editors,
    List<Viewer>? viewers,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      videos: videos ?? this.videos,
      editors: editors ?? this.editors,
      viewers: viewers ?? this.viewers,
    );
  }


  static User _placeholderUser(String userId) {
    return User(
      userId: userId,
      name: '',
      emailAddress: '',
      photoUrl: '',
    );
  }
}


