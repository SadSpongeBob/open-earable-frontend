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
    final name = json['name'] as String;
    final emailAddress = json['emailAddress'] as String;

    final roleRaw = json['role'];
    if (roleRaw is! String) {
      throw StateError('Expected "role" as String but got ${roleRaw.runtimeType}');
    }

    final pictureUrl =
        (json['pictureUrl'] as String?) ?? (json['photoUrl'] as String?);

    return ProjectUser(
      userId: userId,
      name: name,
      emailAddress: emailAddress,
      role: ProjectRole.fromApi(userId: userId, role: roleRaw),
      pictureUrl: pictureUrl,
    );
  }
}