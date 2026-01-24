class User {
  final String userId;
  final String name;
  final String emailAddress;
  final String? photoUrl;

  User({
    required this.userId,
    required this.name,
    required this.emailAddress,
    required this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': userId,
    'name': name,
    'emailAddress': emailAddress,
    'photoUrl': photoUrl,
  };
}

enum ProjectRole { owner, editor, viewer }

extension ProjectRoleLabel on ProjectRole {
  String get label => switch (this) {
    ProjectRole.owner => 'Owner',
    ProjectRole.editor => 'Editor',
    ProjectRole.viewer => 'Viewer',
  };
}

class ProjectUserEntry {
  final User user;
  final ProjectRole role;

  const ProjectUserEntry({
    required this.user,
    required this.role,
  });

  ProjectUserEntry copyWith({
    User? user,
    ProjectRole? role,
  }) {
    return ProjectUserEntry(
      user: user ?? this.user,
      role: role ?? this.role,
    );
  }
}
