class ProjectUserDto {
  final String userId;
  final String name;
  final String emailAddress;
  final String role;
  final String? pictureUrl;

  const ProjectUserDto({
    required this.userId,
    required this.name,
    required this.emailAddress,
    required this.role,
    required this.pictureUrl,
  });

  factory ProjectUserDto.fromJson(Map<String, dynamic> json) {
    return ProjectUserDto(
      userId: json['userId'] as String,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      role: json['role'] as String,
      pictureUrl: json['pictureUrl'] as String?,
    );
  }
}
