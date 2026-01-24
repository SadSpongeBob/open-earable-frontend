class ProjectEndpoints {
  static const String base = '/api/project';

  static const String projects = base;

  static String project(String projectId) => '$base/$projectId';

  static String projectUsers(String projectId) => '$base/$projectId/user';

  static String deleteProject(String projectId) => '$base/$projectId/delete';

  static String addProjectUser(String projectId) => '$base/$projectId/user';

  static String updateProjectUser(String projectId, String userId) =>
      '$base/$projectId/user/$userId';

  static String removeProjectUser(String projectId, String userId) =>
      '$base/$projectId/user/$userId';
}
