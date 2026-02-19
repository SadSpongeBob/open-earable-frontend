import 'package:openearable/api/models/project/project_role.dart';

/// Represents a user within a project, including their identity and role.
///
/// Each project user has a unique ID, name, email, and assigned [ProjectRole]
/// which determines their permissions within the project. Optionally, a
/// profile picture URL can be stored.
/// 
/// Parameters:
/// - [userId]: Unique identifier for the user.
/// - [name]: The display name of the user.
/// - [emailAddress]: The email address of the user.
/// - [role]: The role assigned to the user in this project.
/// - [pictureUrl]: Optional URL to the user's profile picture.
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

  /// Creates a [ProjectUser] from a JSON map.
  /// 
  /// Throws a [TypeError] if any required field is missing or of the wrong type.
  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final name = json['name'] as String;
    final emailAddress = json['emailAddress'] as String;
    final roleRaw = json['role'] as String;
    final pictureUrl = json['pictureUrl'] as String?;

    return ProjectUser(
      userId: userId,
      name: name,
      emailAddress: emailAddress,
      role: ProjectRole.fromApi(userId: userId, role: roleRaw),
      pictureUrl: pictureUrl,
    );
  }
}
