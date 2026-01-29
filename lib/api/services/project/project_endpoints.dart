class ProjectEndpoints {
  static const String baseUrl = '/api/project';

  static String project(String projectId) => '$baseUrl/$projectId';

  static String projectUsers(String projectId) => '$baseUrl/$projectId/user';

  static String deleteProject(String projectId) => '$baseUrl/$projectId/delete';

  static const String duplicateProject = '$baseUrl/duplicate';
}
