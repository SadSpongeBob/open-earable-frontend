import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/models/project/project.dart';
import 'package:openearable/api/local_media.dart';

class MockDio extends Mock implements Dio {}
class MockLocalMedia extends Mock implements LocalMedia {}

void main() {
  late MockDio dio;
  late ProjectService svc;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dio = MockDio();
    svc = ProjectService(dioClient: dio, localMedia: MockLocalMedia());
  });

  test('getProjects parses list', () async {
    when(() => dio.get(any())).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), data: [
      {'projectId': 'p1', 'name': 'P1', 'recordingAmount': 0, 'userAmount': 0}
    ]));

    final res = await svc.getProjects();
    expect(res.length, 1);
    expect(res.first.id, 'p1');
  });

  test('createProject returns created project', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), data: {'projectId': 'p2', 'name': 'P2', 'ownerId': 'o', 'users': [], 'recordings': []}));

    final p = await svc.createProject('P2');
    expect(p.id, 'p2');
  });

  test('deleteProject calls delete', () async {
    when(() => dio.delete(any())).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '')));
    await svc.deleteProject('p1');
    verify(() => dio.delete(any())).called(1);
  });
}
