import 'package:dio/dio.dart';
import 'package:openearable/api/services/project/project_endpoints.dart';
import '../../models/auth/user.dart';
import '../../models/project.dart';

class ProjectService {
  final Dio dioClient;

  ProjectService({required this.dioClient});

  Future<List<Project>> getProjects() async {
    final res = await dioClient.get<dynamic>(ProjectEndpoints.projects);
    final data = res.data;

    if (data is! List) {
      throw StateError('Expected List from GET ${ProjectEndpoints.projects}');
    }

    return data
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject(String name) async {
    final res = await dioClient.post<dynamic>(
      ProjectEndpoints.projects,
      data: {'name': name},
    );

    if (res.data is! Map<String, dynamic>) {
      throw StateError('Expected object from POST ${ProjectEndpoints.projects}');
    }

    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> renameProject(String projectId, String name) async {
    await dioClient.patch<dynamic>(
      ProjectEndpoints.project(projectId),
      data: {'name': name},
    );
  }

  Future<Project> duplicateProject(String projectId) async {
    final res = await dioClient.post<dynamic>(
      ProjectEndpoints.duplicateProject(projectId),
    );

    if (res.data is! Map<String, dynamic>) {
      throw StateError(
          'Expected object from POST ${ProjectEndpoints.duplicateProject(projectId)}');
    }

    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteProject(String projectId) async {
    await dioClient.delete<dynamic>(
      ProjectEndpoints.project(projectId),
    );
  }

  Future<List<User>> getProjectUsers(String projectId) async {
    final res = await dioClient.get<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
    );
    final data = res.data;

    if (data is! List) {
      throw StateError(
          'Expected List from GET ${ProjectEndpoints.projectUsers(projectId)}');
    }

    final users = <String, User>{};

    for (final entry in data) {
      if (entry is Map<String, dynamic> && entry.containsKey('id')) {
        final u = User.fromJson(entry);
        users[u.userId] = u;
        continue;
      }
      if (entry is Map<String, dynamic> &&
          entry['user'] is Map<String, dynamic>) {
        final u = User.fromJson(entry['user'] as Map<String, dynamic>);
        users[u.userId] = u;
        continue;
      }
      throw StateError('Unsupported user entry: ${entry.runtimeType}');
    }

    return users.values.toList();
  }

  Future<void> addUser(String projectId, String userId, String roleName) async {
    await dioClient.post<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
      data: {
        'userId': userId,
        'role': roleName.toLowerCase(),
      },
    );
  }

  Future<void> changeUserRole(
      String projectId,
      String userId,
      String roleName,
      ) async {
    await dioClient.patch<dynamic>(
      ProjectEndpoints.projectUser(projectId, userId),
      data: {'role': roleName.toLowerCase()},
    );
  }

  Future<void> removeUser(String projectId, String userId) async {
    await dioClient.delete<dynamic>(
      ProjectEndpoints.projectUser(projectId, userId),
    );
  }
}
