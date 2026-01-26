import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import '../../models/auth/user.dart';
import '../../models/project.dart';
import 'project_endpoints.dart';

class ProjectService {
  final Dio dioClient;

  ProjectService({required this.dioClient});

  Future<List<Project>> getProjects() async {
    final res = await dioClient.get<dynamic>(ProjectEndpoints.projects);
    final data = res.asList();

    return data
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject(String name) async {
    final res = await dioClient.post<dynamic>(
      ProjectEndpoints.projects,
      data: {'name': name},
    );

    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<void> renameProject(String projectId, String name) async {
    await dioClient.put<dynamic>(
      ProjectEndpoints.project(projectId),
      data: {'name': name},
    );
  }

  Future<void> deleteProject(String projectId) async {
    await dioClient.delete<dynamic>(
      ProjectEndpoints.deleteProject(projectId),
    );
  }

  Future<List<User>> getProjectUsers(String projectId) async {
    final res = await dioClient.get<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
    );

    final data = res.asList();

    return data
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
