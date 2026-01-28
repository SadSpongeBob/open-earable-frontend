class ProjectMetadata {
  final String id;
  final String name;
  final int recordingAmount;
  final int userAmount;

  const ProjectMetadata({
    required this.id,
    required this.name,
    required this.recordingAmount,
    required this.userAmount,
  });

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
    );
  }

  ProjectMetadata copyWith({required String name}) {
    return ProjectMetadata(
      id: id,
      name: name,
      recordingAmount: recordingAmount,
      userAmount: userAmount,
    );
  }
}
