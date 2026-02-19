import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/utils/helpers.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import '../../client_dio.dart';
import '../../models/project/project.dart';
import '../../models/project/project_role.dart';
import '../../models/project/project_user.dart';
import 'project_endpoints.dart';

/// Service for managing projects in both cloud and local storage.
///
/// Handles CRUD operations for projects, local project persistence,
/// project duplication, and project user management.
///
/// Uses a Dio client for network requests and LocalMedia for filesystem operations.
class ProjectService {
  /// Dio client used for network API requests.
  final Dio _dioClient;

  /// LocalMedia used to manage project directories and metadata files on disk.
  final LocalMedia _localMedia;

  /// Creates a new [ProjectService] with the given [_dioClient] and [_localMedia].
  ProjectService({required Dio dioClient, required LocalMedia localMedia})
    : _dioClient = dioClient,
      _localMedia = localMedia;

  // ======================================================================
  // Cloud Project Operations
  // ======================================================================

  /// Fetches all projects from the cloud as [ProjectMetadata] list.
  Future<List<ProjectMetadata>> getProjects() async {
    final res = await _dioClient.get(ProjectEndpoints.baseUrl);
    final data = res.asList();

    return data
        .map((e) => ProjectMetadata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a specific cloud project by [projectId].
  Future<Project> getProject(String projectId) async {
    final res = await _dioClient.get(ProjectEndpoints.project(projectId));
    final data = res.asMap();

    return Project.fromJson(data);
  }

  /// Creates a new project in the cloud with [name].
  Future<Project> createProject(String name) async {
    final res = await _dioClient.post(
      ProjectEndpoints.baseUrl,
      data: {'name': name},
    );

    final data = res.asMap();

    return Project.fromJson(data);
  }

  /// Updates a cloud project's name.
  Future<void> renameProject(String projectId, String name) async {
    await _dioClient.put(
      ProjectEndpoints.project(projectId),
      data: {'name': name},
    );
  }

  /// Moves recordings to a target project in the cloud.
  Future<void> moveRecordings({
    required List<String> recordingIds,
    required String? targetProjectId,
  }) async {
    await _dioClient.put(
      ProjectEndpoints.moveRecordings,
      data: {
        'recordingIds': recordingIds,
        'targetProjectId': targetProjectId,
      },
    );
  }

  /// Deletes a cloud project by [projectId].
  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete(ProjectEndpoints.deleteProject(projectId));
  }

  /// Duplicates a cloud project by [projectId].
  Future<ProjectMetadata> duplicateProject(String projectId) async {
    final res = await _dioClient.post<dynamic>(
      ProjectEndpoints.duplicateProject(projectId),
    );
    return ProjectMetadata.fromJson(res.asMap());
  }

  // ======================================================================
  // Local Project Operations
  // ======================================================================

  /// Creates a new local project with [name] and optional [id].
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

  /// Returns a list of all local project IDs.
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

  /// Fetches all locally stored projects.
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
        continue;
      }
      final name = (meta['name'] as String?) ?? 'Project - $projectId';

      projects.add(ProjectMetadata.local(projectId, name));
    }

    return projects;
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

  /// Duplicates a local project.
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

  /// Deletes a local project by [projectId].
  Future<void> deleteLocalProject(String projectId) async {
    final dir = _localMedia.projectDir(projectId);
    if (!await dir.exists()) return;

    await dir.delete(recursive: true);
  }

  // ======================================================================
  // Project Users Management
  // ======================================================================

  /// Fetches all users for a project.
  Future<List<ProjectUser>> getProjectUsers(String projectId) async {
    final res = await _dioClient.get(ProjectEndpoints.projectUsers(projectId));

    final list = res.asList();

    return list
        .map((e) => ProjectUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds a user with [emailAddress] and [role] to the project.
  Future<List<ProjectUser>> addProjectUser({
    required String projectId,
    required String emailAddress,
    required ProjectRoleType role,
  }) async {
    final res = await _dioClient.post<dynamic>(
      ProjectEndpoints.projectUsers(projectId),
      data: {
        'emailAddress': emailAddress.trim(),
        'role': role.toApi(),
      },
    );

    final list = res.asList();

    return list
        .map((e) => ProjectUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the role of a user [userId] in a project.
  Future<void> updateProjectUserRole({
    required String projectId,
    required String userId,
    required ProjectRoleType role,
  }) async {
    await _dioClient.put<dynamic>(
      ProjectEndpoints.updateProjectUserRole(projectId),
      data: {
        'userId': userId,
        'role': role.toApi(),
      },
    );
  }

  /// Current user leaves a project.
  Future<void> leaveProject({
    required String projectId,
  }) async {
    await _dioClient.delete<dynamic>(
      ProjectEndpoints.leaveProject(projectId),
    );
  }

  /// Removes a user [userId] from a project.
  Future<void> removeUserFromProject({
    required String projectId,
    required String userId,
  }) async {
    await _dioClient.delete<dynamic>(
      ProjectEndpoints.removeProjectUser(projectId, userId),
    );
  }

  // ======================================================================
  // Helpers
  // ======================================================================

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
  
  /// Migrates a local project directory if [oldId] exists.
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

  /// Overwrites metadata file for project [projectId] if directory exists.
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
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return ProjectService(dioClient: dio, localMedia: localMedia);
});

