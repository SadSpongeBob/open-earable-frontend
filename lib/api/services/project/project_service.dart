import 'dart:convert';
import 'dart:io';
import 'package:openearable/app/utils/helpers.dart';
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
    final res = await _dioClient.get(ProjectEndpoints.baseUrl);
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
    final res = await _dioClient.get(ProjectEndpoints.project(projectId));
    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<Project> createProject(String name) async {
    final res = await _dioClient.post(
      ProjectEndpoints.baseUrl,
      data: {'name': name},
    );

    final data = res.asMap();

    return Project.fromJson(data);
  }

  Future<ProjectMetadata> createLocalProject({
    required String name,
    String? id,
  }) async {
    final projectId = id ?? Helpers.getProjectId();
    final project = ProjectMetadata.local(projectId, name);

    final metaFile = _localMedia.projectMetaFile(projectId);
    await metaFile.parent.create(recursive: true);

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());

    await metaFile.writeAsString(jsonString, flush: true);

    return project;
  }

  Future<void> renameProject(String projectId, String name) async {
    await _dioClient.put(
      ProjectEndpoints.project(projectId),
      data: {'name': name},
    );
  }

  /// Updates the local project on disk.
  ///
  /// If [projectId] is provided, the project is migrated from that old ID:
  /// - The metadata file is renamed/moved.
  /// - Any recordings are moved under the new project folder.
  /// Otherwise, the existing metadata is overwritten in place.
  Future<void> updateLocalProject({
    required ProjectMetadata project,
    String? oldProjectId,
  }) async {
    final newId = project.id;

    if (oldProjectId != null && oldProjectId != newId) {
      await _migrateProjectDirIfExists(oldProjectId, newId);
    }

    await overwriteMetaIfProjectDirExists(newId, project);
  }

  Future<void> _migrateProjectDirIfExists(String oldId, String newId) async {
    final oldDir = _localMedia.projectDir(oldId);
    if (!await oldDir.exists()) return;

    final newDir = _localMedia.projectDir(newId);
    if (await newDir.exists()) {
      throw StateError(
        'Target project directory already exists: ${newDir.path}',
      );
    }

    await newDir.parent.create(recursive: true);
    await oldDir.rename(newDir.path);
  }

  Future<void> overwriteMetaIfProjectDirExists(
    String projectId,
    ProjectMetadata project,
  ) async {
    final dir = _localMedia.projectDir(projectId);
    if (!await dir.exists()) return;

    final metaFile = _localMedia.projectMetaFile(projectId);

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());

    await metaFile.writeAsString(jsonString, flush: true);
  }

  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete(ProjectEndpoints.deleteProject(projectId));
  }

  Future<void> deleteLocalProject(String projectId) async {
    final dir = _localMedia.projectDir(projectId);
    if (!await dir.exists()) return;

    await dir.delete(recursive: true);
  }

  Future<ProjectMetadata> duplicateProject(String projectId) async {
    final res = await _dioClient.post(
      ProjectEndpoints.duplicateProject,
      data: {'projectId': projectId},
    );
    final data = res.asMap();
    return ProjectMetadata.fromJson(data);
  }

  Future<void> duplicateLocalProject(
    String projectId,
    ProjectMetadata newProject,
  ) async {
    final sourceDir = _localMedia.projectDir(projectId);
    if (!await sourceDir.exists()) return;

    final destinationDir = _localMedia.projectDir(newProject.id);
    if (await destinationDir.exists()) {
      throw StateError('Destination already exists: ${destinationDir.path}');
    }

    try {
      await _copyDirectory(sourceDir, destinationDir);
      await overwriteMetaIfProjectDirExists(newProject.id, newProject);
    } catch (_) {
      // Rollback
      if (await destinationDir.exists()) {
        await destinationDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Copies directory from [source] to [destination].
  /// Any sub directory (`/{recordingId}`) will be regenerated
  /// meaning the sub directories will be renamed to a `uuid`.
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final newPath = p.join(destination.path, p.basename(entity.path));

      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        final newRecordingId = Helpers.getRecordingId();
        final newDir = Directory(p.join(destination.path, newRecordingId));
        await _copyDirectory(entity, newDir);
      } else if (entity is Link) {
        final target = await entity.target();
        await Link(newPath).create(target);
      }
    }
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
