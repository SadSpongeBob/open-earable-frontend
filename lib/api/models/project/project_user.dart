import 'package:openearable/api/models/project/project_role.dart';

class ProjectUser {
  final String userId;
  final String name;
  final String emailAddress;
  final ProjectRole role;
  final String? pictureUrl;

  const ProjectUser({
    required this.userId,
    required this.name,
    required this.emailAddress,
    required this.role,
    required this.pictureUrl,
  });

  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;

    final roleRaw = json['role'];
    final roleString = roleRaw is String
        ? roleRaw
        : (roleRaw is Map<String, dynamic> ? (roleRaw['role'] as String?) : null);

    return ProjectUser(
      userId: userId,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      role: ProjectRole.fromApi(
        userId: userId,
        role: roleString ?? 'VIEWER',
      ),
      pictureUrl: json['pictureUrl'] as String?,
    );
  }
}

