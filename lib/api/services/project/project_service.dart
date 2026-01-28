import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import '../../models/auth/user.dart';
import '../../models/project/project.dart';
import 'project_endpoints.dart';

class ProjectService {
  final Dio _dioClient;
  final LocalMedia _localMedia;

  ProjectService({required Dio dioClient, required LocalMedia localMedia})
    : _dioClient = dioClient,
      _localMedia = localMedia;

  Future<List<ProjectMetadata>> getProjects() async {
    final res = await _dioClient.get<dynamic>(ProjectEndpoints.baseUrl);
    final data = res.asList();

    return data
        .map((e) => ProjectMetadata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProjectMetadata>> getLocalProjects() async {
    final projectIds = await getLocalProjectIds();

    final projects = <ProjectMetadata>[];

    for (final projectId in projectIds) {
      final metaFile = _localMedia.projectMetaFile(projectId);
      if (!await metaFile.exists()) continue;

      Map<String, dynamic> meta;
      try {
        meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        // corrupted metadata -> skip project
        continue;
      }
      final name = (meta['name'] as String?) ?? 'Project - $projectId';

      projects.add(ProjectMetadata.local(projectId, name));
    }

    return projects;
  }

  Future<List<String>> getLocalProjectIds() async {
    if (!await _localMedia.baseDir.exists()) return [];

    final entities = await _localMedia.baseDir
        .list(followLinks: false)
        .toList();

    return entities
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .where((id) => id != LocalMedia.defaultProjectId)
        .toList();
  }

  Future<Project> getProject(String projectId) async {
    final res = await _dioClient.get<dynamic>(
      ProjectEndpoints.project(projectId),
    );
    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<Project> createProject(String name) async {
    final res = await _dioClient.post<dynamic>(
      ProjectEndpoints.baseUrl,
      data: {'name': name},
    );

    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<void> renameProject(String projectId, String name) async {
    await _dioClient.put<dynamic>(
      ProjectEndpoints.project(projectId),
      data: {'name': name},
    );
  }

  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete<dynamic>(ProjectEndpoints.deleteProject(projectId));
  }

  Future<List<User>> getProjectUsers(String projectId) async {
    final res = await _dioClient.get<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
    );

    final data = res.asList();

    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return ProjectService(dioClient: dio, localMedia: localMedia);
});
