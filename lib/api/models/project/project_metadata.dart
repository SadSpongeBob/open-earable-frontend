/// Represents metadata about a project, either local or cloud-based.
/// 
/// Parameters:
/// - [id]: Unique identifier of the project.
/// - [name]: The human-readable project name.
/// - [recordingAmount]: The number of recordings associated with this project.
/// - [userAmount]: The number of users with access to this project.
/// - [projectSource]: Indicates whether the project is stored locally or in the cloud.
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

  /// Creates a local project metadata instance with zero recordings and users.
  factory ProjectMetadata.local(String id, String name) {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: 0,
      userAmount: 0,
      projectSource: ProjectSource.local,
    );
  }

  /// Creates a cloud project metadata instance with zero recordings and users.
  factory ProjectMetadata.cloud(String id, String name) {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: 0,
      userAmount: 0,
      projectSource: ProjectSource.cloud,
    );
  }

  /// Creates a [ProjectMetadata] instance from a JSON map (typically from API response).
  /// 
  /// Expects keys: 'projectId', 'name', 'recordingAmount', 'userAmount'.
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
    'projectSource': projectSource.json,
  };
}

/// Indicates the source of the project: either local or cloud.
enum ProjectSource {
  local,
  cloud;

  /// Returns the string representation used in JSON (uppercase).
  String get json => name.toUpperCase();

  /// Converts a JSON string (case-insensitive) to a [ProjectSource] value.
  static ProjectSource fromJson(String value) =>
      ProjectSource.values.byName(value.toUpperCase());
}
