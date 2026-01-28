import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import '../../models/project/project.dart';
import '../../models/project/project_user_dto.dart';
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

  // Project Users Management

  Future<List<ProjectUserDto>> getProjectUsers(String projectId) async {
    final res = await dioClient.get<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
    );

    final map = res.asMap();
    final data = map['data'];

    if (data is! List) {
      throw StateError('Expected {data: List} from GET ${ProjectEndpoints.projectUsers(projectId)}');
    }

    return data
        .map((e) => ProjectUserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProjectUserDto>> addProjectUser({
    required String projectId,
    required String emailAddress,
    required String role,
  }) async {
    final res = await dioClient.post<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
      data: {
        'emailAddress': emailAddress.trim(),
        'role': role.trim().toUpperCase(),
      },
    );

    final map = res.asMap();
    final data = map['data'];

    if (data is! List) {
      throw StateError('Expected {data: List} from POST ${ProjectEndpoints.projectUsers(projectId)}');
    }

    return data
        .map((e) => ProjectUserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }


  Future<void> removeUserFromProject({
    required String projectId,
    required String userId,
  }) async {
    await dioClient.delete<dynamic>(
      ProjectEndpoints.removeProjectUser(projectId, userId),
    );
  }

}

final projectServiceProvider = Provider<ProjectService>((ref) {
  final dio = ref.read(apiDioProvider);
  return ProjectService(dioClient: dio);
});
