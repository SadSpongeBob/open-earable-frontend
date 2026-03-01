import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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

class _TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentPng = base64Decode(
    // 1x1 transparent PNG
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgGv0tWQAAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(_transparentPng.buffer);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(<Recording>[]);
    registerFallbackValue(<ProjectMetadata>[]);
    registerFallbackValue(ProjectMetadata.local('fallback', 'Fallback'));
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

      final overrides = <Override>[
        projectServiceProvider.overrideWithValue(projectService),
        recordingServiceProvider.overrideWithValue(recordingService),
        userServiceProvider.overrideWithValue(userService),
        localMediaProvider.overrideWithValue(localMedia),
        sessionProvider.overrideWith((ref) => FakeSessionNotifier(authState)),
        homeStateProvider.overrideWith((ref) {
          final notifier = HomeStateNotifier();
          if (initialHomeState != null) {
            notifier.state = initialHomeState;
          }
          return notifier;
        }),
      ];

      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      return container;
    }

    GoRouter router(Widget child) {
      return GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => child,
          ),
          GoRoute(
            path: '/dummy',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    Future<void> pumpHome(
        WidgetTester tester, {
          required ProviderContainer container,
        }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: DefaultAssetBundle(
            bundle: _TestAssetBundle(),
            child: MaterialApp.router(
              routerConfig: router(const HomePage()),
            ),
          ),
        ),
      );
      await tester.pump(); // first frame
      await tester.pump(const Duration(milliseconds: 50)); // postFrameCallback
    }

    testWidgets('renders without crashing (guest, default project)', (tester) async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default')],
          openProjectId: LocalMedia.defaultProjectId,
          recordings: const [],
        ),
      );

      // init() will call these:
      when(() => projectService.getLocalProjects()).thenAnswer((_) async => <ProjectMetadata>[]);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => <Recording>[]);

      await pumpHome(tester, container: container);

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('long press on non-default project enters project selection mode', (tester) async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
          ],
          openProjectId: LocalMedia.defaultProjectId,
          recordings: const [],
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => <ProjectMetadata>[]);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => <Recording>[]);

      await pumpHome(tester, container: container);

      // ProjectBar uses InkWell per tile; longPress the project name
      await tester.longPress(find.text('P1'));
      await tester.pump();

      final state = container.read(homeStateProvider);
      expect(state.isProjectSelectionMode, isTrue);
      expect(state.selectedProjectIds, contains('p1'));
    });

    testWidgets('tap project while in selection mode toggles selection (does not open)', (tester) async {
      final container = buildContainer(
        authState: const AuthState(mode: AuthMode.guest),
        initialHomeState: HomeState.initial().copyWith(
          projects: [
            ProjectMetadata.local(LocalMedia.defaultProjectId, 'Default'),
            ProjectMetadata.local('p1', 'P1'),
            ProjectMetadata.local('p2', 'P2'),
          ],
          openProjectId: 'p1',
          isProjectSelectionMode: true,
          selectedProjectIds: {'p2'},
          recordings: const [],
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => <ProjectMetadata>[]);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => <Recording>[]);

      await pumpHome(tester, container: container);

      await tester.tap(find.text('P1'));
      await tester.pump();

      final state = container.read(homeStateProvider);
      expect(state.selectedProjectIds, containsAll(<String>{'p2', 'p1'}));
      expect(state.openProjectId, 'p1'); // unchanged
    });

    testWidgets('long press on a recording enters recording selection mode', (tester) async {
      final r1 = MockRecording();
      when(() => r1.id).thenReturn('r1');
      when(() => r1.name).thenReturn('Rec 1');
      when(() => r1.isUploading).thenReturn(false);
      when(() => r1.isUploaded).thenReturn(false);
      when(() => r1.isUploadFailed).thenReturn(false);
      when(() => r1.thumbnailProvider).thenReturn(const AssetImage('assets/any.png'));
      when(() => r1.isCloud).thenReturn(false);

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

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => <ProjectMetadata>[]);
      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => <Recording>[]);

      await pumpHome(tester, container: container);

      await tester.longPress(find.text('Rec 1'));
      await tester.pump();

      final state = container.read(homeStateProvider);
      expect(state.isRecordingSelectionMode, isTrue);
      expect(state.selectedRecordingIds, contains('r1'));
    });

    testWidgets('shows Users button for authenticated + cloud non-default open project, opens UsersPopup', (tester) async {
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
          recordings: const [],
        ),
      );

      when(() => projectService.getLocalProjects()).thenAnswer((_) async => <ProjectMetadata>[]);
      when(() => projectService.getProjects()).thenAnswer((_) async => <ProjectMetadata>[ProjectMetadata.cloud('cp1', 'Cloud 1')]);

      when(() => recordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => <Recording>[]);

      await pumpHome(tester, container: container);

      expect(find.byType(UsersButton), findsOneWidget);

      await tester.tap(find.byType(UsersButton));
      await tester.pumpAndSettle();

      expect(find.byType(UsersPopup), findsOneWidget);
    });
  });
}