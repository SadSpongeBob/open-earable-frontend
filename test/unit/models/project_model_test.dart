import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/project/project_metadata.dart';

void main() {
  group('Project model', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'projectId': 'p1',
        'name': 'Project One',
        'ownerId': 'owner1',
        'users': [
          {'userId': 'u1', 'role': 'OWNER'},
        ],
        'recordings': [],
      };

      final p = Project.fromJson(json);
      expect(p.id, 'p1');
      expect(p.name, 'Project One');
      expect(p.isOwner('owner1'), isTrue);
      expect(p.isEditor('u1'), isTrue);
      expect(p.isViewer('u1'), isTrue);

      final meta = p.toMetadata();
      expect(meta.id, 'p1');
      expect(meta.name, 'Project One');
    });

    test('copyWith updates name', () {
      final p = Project(id: 'id', name: 'a', ownerId: 'o', recordings: [], users: []);
      final p2 = p.copyWith(name: 'b');
      expect(p2.name, 'b');
      expect(p2.id, p.id);
    });
  });

  group('ProjectRole', () {
    test('fromApi maps roles and permissions', () {
      final owner = ProjectRole.fromApi(userId: 'x', role: 'OWNER');
      final editor = ProjectRole.fromApi(userId: 'y', role: 'EDITOR');
      final viewer = ProjectRole.fromApi(userId: 'z', role: 'VIEWER');

      expect(owner.canManageUsers(), isTrue);
      expect(editor.canEditVideos(), isTrue);
      expect(viewer.canEditVideos(), isFalse);

      expect(owner.toApi(), 'OWNER');
      expect(editor.toApi(), 'EDITOR');
      expect(viewer.toApi(), 'VIEWER');
    });

    test('ProjectRoleType and extension methods', () {
      expect(ProjectRoleType.owner.toApi(), 'OWNER');
      expect(ProjectRoleType.editor.toApi(), 'EDITOR');
      expect(ProjectRoleType.viewer.toApi(), 'VIEWER');

      expect(ProjectRoleType.owner.label, 'Owner');
      expect(ProjectRoleType.editor.label, 'Editor');
      expect(ProjectRoleType.viewer.label, 'Viewer');

      expect(() => ProjectRoleTypeApi.fromApi('BAD'), throwsA(isA<ArgumentError>()));
      expect(ProjectRoleTypeApi.fromApi('owner'), ProjectRoleType.owner);
    });

  });

  group('ProjectMetadata', () {
    test('fromJson and toJson and factories', () {
      final json = {'projectId': 'p1', 'name': 'P', 'recordingAmount': 2, 'userAmount': 3};
      final m = ProjectMetadata.fromJson(json);
      expect(m.id, 'p1');
      expect(m.recordingAmount, 2);
      expect(m.userAmount, 3);

      final local = ProjectMetadata.local('l1', 'L');
      expect(local.projectSource, ProjectSource.local);

      final cloud = ProjectMetadata.cloud('c1', 'C');
      expect(cloud.projectSource, ProjectSource.cloud);

      final map = m.toJson();
      expect(map['id'], 'p1');
      expect(map['name'], 'P');
      expect(map['projectSource'], 'CLOUD');
    });

    test('copyWith retains id', () {
      final m = ProjectMetadata.local('i1', 'N');
      final m2 = m.copyWith(name: 'NewName');
      expect(m2.id, 'i1');
      expect(m2.name, 'NewName');
    });
  });

}
