class ProjectEndpoints {
  static const String projects = '/projects';

  static String project(String projectId) => '/projects/$projectId';

  static String duplicateProject(String projectId) =>
      '/projects/$projectId/duplicate';

  static String projectUsers(String projectId) => '/projects/$projectId/users';

  static String projectUser(String projectId, String userId) =>
      '/projects/$projectId/users/$userId';
  
}
