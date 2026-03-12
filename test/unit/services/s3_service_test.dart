import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/services/s3/s3_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late S3Service s3;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dio = MockDio();
    s3 = S3Service(dio: dio);
  });

  test('uploadFile forwards to dio.put and sets Content-Length header', () async {
    final tmp = Directory.systemTemp.createTempSync('s3_test');
    final file = File('${tmp.path}/test.bin')..writeAsBytesSync(List.generate(100, (i) => i % 256));

    Options? capturedOptions;
    when(() => dio.put(any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        onSendProgress: any(named: 'onSendProgress'),
        cancelToken: any(named: 'cancelToken'))).thenAnswer((inv) async {
      capturedOptions = inv.namedArguments[Symbol('options')] as Options?;
      return Response(requestOptions: RequestOptions(path: ''), data: 'ok');
    });

    final resp = await s3.uploadFile(
      putUrl: 'https://example.com/put',
      file: file,
      headers: {'x-amz-meta-test': '1'},
    );

    expect(resp.data, 'ok');
    expect(capturedOptions, isNotNull);
    final hdrs = capturedOptions!.headers!;
    expect(hdrs['x-amz-meta-test'], '1');
    expect(hdrs['Content-Length'], file.lengthSync().toString());

    tmp.deleteSync(recursive: true);
  });

  test('downloadToFile completes on success', () async {
    when(() => dio.download(any(), any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'))).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '')));

    final tmp = Directory.systemTemp.createTempSync('s3dl');
    final out = '${tmp.path}/out.bin';

    await s3.downloadToFile(getUrl: 'https://example.com/get', filePath: out);

    // dio.download stubbed, so file won't actually be created; ensure no exception
    tmp.deleteSync(recursive: true);
  });

  test('downloadToFile throws friendly message for 403', () async {
    final resp = Response(requestOptions: RequestOptions(path: ''), statusCode: 403);
    final dioEx = DioException(requestOptions: RequestOptions(path: ''), response: resp);

    when(() => dio.download(any(), any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'))).thenThrow(dioEx);

    final tmp = Directory.systemTemp.createTempSync('s3dl403');
    final out = '${tmp.path}/out.bin';

    expect(
        () => s3.downloadToFile(getUrl: 'https://example.com/get', filePath: out),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Presigned GET URL'))));

    tmp.deleteSync(recursive: true);
  });

  test('downloadToFile rethrows other DioExceptions', () async {
    final resp = Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
    final dioEx = DioException(requestOptions: RequestOptions(path: ''), response: resp);

    when(() => dio.download(any(), any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'))).thenThrow(dioEx);

    final tmp = Directory.systemTemp.createTempSync('s3dl500');
    final out = '${tmp.path}/out.bin';

    expect(() => s3.downloadToFile(getUrl: 'https://example.com/get', filePath: out), throwsA(isA<DioException>()));

    tmp.deleteSync(recursive: true);
  });

  test('uploadFile handles DioError gracefully', () async {
    final file = File('${Directory.systemTemp.path}/test_error.bin')..writeAsBytesSync([1, 2, 3]);
    when(() => dio.put(any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
        onSendProgress: any(named: 'onSendProgress'),
        cancelToken: any(named: 'cancelToken')))
      .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    expect(
      () => s3.uploadFile(
        putUrl: 'https://example.com/put',
        file: file,
        headers: {},
      ),
      throwsA(isA<DioException>()),
    );
  });

  test('downloadFile saves content to local file', () async {
    final tmp = Directory.systemTemp.createTempSync('s3_download_test');
    final file = File('${tmp.path}/downloaded.bin');
    when(() => dio.download(any(), any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'))).thenAnswer((inv) async {
      final path = inv.positionalArguments[1] as String;
      await File(path).writeAsBytes([1, 2, 3]);
      return Response(requestOptions: RequestOptions(path: ''));
    });

    await s3.downloadToFile(getUrl: 'https://example.com/get', filePath: file.path);

    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync(), [1, 2, 3]);

    tmp.deleteSync(recursive: true);
  });
}
