import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/client_dio.dart';

import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/home_state.dart';
import 'package:openearable/features/home/widgets/users_button.dart';
import 'package:openearable/features/home/widgets/users_popup.dart';

class MockProjectService extends Mock implements ProjectService {}
class MockRecordingService extends Mock implements RecordingService {}
class MockUserService extends Mock implements UserService {}
class MockLocalMedia extends Mock implements LocalMedia {}
class MockRecording extends Mock implements Recording {}

class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(AuthState initial) : super() {
    state = initial;
  }
}

/// Fixes "Message corrupted" by returning a valid StandardMessageCodec payload for AssetManifest.bin
class FakeAssetBundle extends CachingAssetBundle {
  static final Uint8List _onePxPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO3Z1mYAAAAASUVORK5CYII=',
  );

  static final ByteData _emptyManifestBin = (() {
    final bytes = const StandardMessageCodec().encodeMessage(<String, dynamic>{})!;
    return ByteData.view(bytes.buffer);
  })();

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('AssetManifest.bin')) return _emptyManifestBin;

    if (key.endsWith('AssetManifest.json')) {
      final bytes = utf8.encode('{}');
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }

    if (key.endsWith('.png') ||
        key.endsWith('.jpg') ||
        key.endsWith('.jpeg') ||
        key.endsWith('.webp')) {
      return ByteData.view(_onePxPng.buffer);
    }

    return ByteData.view(Uint8List(0).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('AssetManifest.json')) return '{}';
    return '';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<Recording>[]);
    registerFallbackValue(<ProjectMetadata>[]);
  });

  group('HomePage - integration-ish widget tests', () {
    late MockProjectService projectService;
    late MockRecordingService recordingService;
    late MockUserService userService;
    late MockLocalMedia localMedia;

    ProviderContainer buildContainer({
      required AuthState authState,
      HomeState? initialHomeState,
    }) {
      projectService = MockProjectService();
      recordingService = MockRecordingService();
      userService = MockUserService();
      localMedia = MockLocalMedia();

      final container = ProviderContainer(
        overrides: [
          projectServiceProvider.overrideWithValue(projectService),
          recordingServiceProvider.overrideWithValue(recordingService),
          userServiceProvider.overrideWithValue(userService),
          localMediaProvider.overrideWithValue(localMedia),
          sessionProvider.overrideWith((ref) => FakeSessionNotifier(authState)),
          homeStateProvider.overrideWith((ref) {
            final notifier = HomeStateNotifier();
            if (initialHomeState != null) notifier.state = initialHomeState;
            return notifier;
          }),
        ],
      );

      addTearDown(container.dispose);
      return container;
    }

    GoRouter router(Widget child) {
      return GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => child),
          GoRoute(path: '/dummy', builder: (_, _) => const SizedBox()),
        ],
      );
    }

    Future<void> pumpHome(
        WidgetTester tester, {
          required ProviderContainer container,
        }) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: DefaultAssetBundle(
            bundle: FakeAssetBundle(),
            child: MaterialApp.router(
              routerConfig: router(const HomePage()),
            ),
          ),
        ),
      );

      await tester.pump(); // build
      await tester.pump(const Duration(milliseconds: 200)); // postframe
    }

    testWidgets('renders without crashing (guest, default project)', (tester) async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
          openProjectId: LocalMedia.defaultProjectId,
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => []);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => []);

      await pumpHome(tester, container: container);

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('long press on a recording enters recording selection mode', (tester) async {
      final r1 = MockRecording();
      when(() => r1.id).thenReturn('r1');
      when(() => r1.name).thenReturn('Rec 1');
      when(() => r1.thumbnailUrl).thenReturn(null);
      when(() => r1.isCloud).thenReturn(false);
      when(() => r1.uploadStatus).thenReturn(UploadStatus.completed);

      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
          ],
          openProjectId: 'p1',
          recordings: [r1],
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => []);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => []);

      await pumpHome(tester, container: container);
      await tester.pump(const Duration(milliseconds: 200));

      final grid = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Rec 1'), 300, scrollable: grid);
      await tester.pump();

      await tester.longPress(find.text('Rec 1'));
      await tester.pump();

      final state = container.read(homeStateProvider);
      expect(state.isRecordingSelectionMode, isTrue);
      expect(state.selectedRecordingIds, contains('r1'));
    });

    testWidgets('shows Users button for authenticated + cloud project', (tester) async {
      final container = buildContainer(
        authState: AuthState(
          mode: AuthMode.authenticated,
          user: User(
            userId: 'me',
            name: 'Me',
            emailAddress: 'me@x.com',
            photoUrl: 'x',
          ),
        ),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.cloud(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.cloud('cp1', 'Cloud 1'),
          ],
          openProjectId: 'cp1',
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => []);
      when(() => projectService.getProjects()).thenAnswer((_) async => [ProjectMetadata.cloud('cp1', 'Cloud 1')]);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => []);

      await pumpHome(tester, container: container);

      expect(find.byType(UsersButton), findsOneWidget);

      await tester.tap(find.byType(UsersButton));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(UsersPopup), findsOneWidget);
    });
  });
}