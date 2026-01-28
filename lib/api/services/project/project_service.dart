import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import '../../models/auth/user.dart';
import '../../models/project/project.dart';
import 'project_endpoints.dart';

class ProjectService {
  final Dio dioClient;

  ProjectService({required this.dioClient});

  Future<List<ProjectMetadata>> getProjects() async {
    final res = await dioClient.get<dynamic>(ProjectEndpoints.baseUrl);
    final data = res.asList();

    return data
        .map((e) => ProjectMetadata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> getProject(String projectId) async {
    final res = await dioClient.get<dynamic>(ProjectEndpoints.project(projectId));
    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<Project> createProject(String name) async {
    final res = await dioClient.post<dynamic>(
      ProjectEndpoints.baseUrl,
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

final projectServiceProvider = Provider<ProjectService>((ref) {
  final dio = ref.read(apiDioProvider);
  return ProjectService(dioClient: dio);
});
