class ProjectMetadata {
  final String id;
  final String name;
  final int recordingAmount;
  final int userAmount;
  final ProjectSource projectSource;

  const ProjectMetadata({
    required this.id,
    required this.name,
    required this.recordingAmount,
    required this.userAmount,
    required this.projectSource,
  });

  factory ProjectMetadata.local(String id, String name) {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: 0,
      userAmount: 0,
      projectSource: ProjectSource.local,
    );
  }

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) {
    final id = json['projectId'] as String;
    final name = json['name'] as String;
    final recordingAmount = json['recordingAmount'] as int;
    final userAmount = json['userAmount'] as int;

    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: recordingAmount,
      userAmount: userAmount,
      projectSource: ProjectSource.cloud,
    );
  }

  ProjectMetadata copyWith({required String name}) {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: recordingAmount,
      userAmount: userAmount,
      projectSource: projectSource,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectSource': projectSource,
  };
}

enum ProjectSource {
  local,
  cloud;

  String get json => name.toUpperCase();

  static ProjectSource fromJson(String value) =>
      ProjectSource.values.byName(value.toUpperCase());
}
