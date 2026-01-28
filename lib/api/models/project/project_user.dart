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
    return ProjectUser(
      userId: json['userId'] as String,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      role: ProjectRole.fromJson(json),
      pictureUrl: json['pictureUrl'] as String?,
    );
  }
}

