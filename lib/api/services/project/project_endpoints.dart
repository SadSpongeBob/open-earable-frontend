class ProjectEndpoints {
  static const String baseUrl = '/api/project';

  static String project(String projectId) => '$baseUrl/$projectId';

  static String projectUsers(String projectId) => '$baseUrl/$projectId/user';

  static String deleteProject(String projectId) => '$baseUrl/$projectId/delete';

  static String duplicateProject(String projectId) => '$baseUrl/$projectId/duplicate';

  static String addProjectUser(String projectId) => '$baseUrl/$projectId/user';

  static String leaveProject(String projectId) => '$baseUrl/$projectId/user';

  static String removeProjectUser(String projectId, String userId) => '$baseUrl/$projectId/user/$userId';

  static const String moveRecordings = '$baseUrl/recording';

  static String updateProjectUserRole(String projectId) => '$baseUrl/$projectId/user';

}
