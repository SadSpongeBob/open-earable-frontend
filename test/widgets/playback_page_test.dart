import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/home_state.dart';
import 'package:openearable/features/playback/state/playback_state.dart';
import 'package:openearable/features/playback/widgets/playback_bar.dart';
import 'package:openearable/features/playback/widgets/rename_dialog.dart';
import 'package:openearable/features/playback/widgets/select_sensors_dialog.dart';
import 'package:openearable/features/playback/widgets/sensor_playback_bar.dart';
import 'package:openearable/features/playback/widgets/speed_badge.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/local_media.dart';
import 'package:go_router/go_router.dart';

class RecordingFake extends Fake implements Recording {}

class MockLocalMedia extends Mock implements LocalMedia {}

class MockVideoController extends Mock
    implements VideoPlayerController, Listenable {
  @override
  void addListener(void Function()? listener) {}

  @override
  void removeListener(void Function()? listener) {}
}

class MockPlaybackController extends Mock implements PlaybackController {}

void main() {
  setUpAll(() {
    registerFallbackValue(RecordingFake());
    registerFallbackValue(const Duration());
  });

  group('Playback Widget Test', () {
    late Recording recording;
    late Sensor sensor;
    late MockVideoController fakeVideo;
    late MockPlaybackController mockPlaybackController;

    setUp(() {
      recording = Recording(
        id: 'rec1',
        name: 'IntegrationTestVideo',
        source: RecordingSource.local,
        projectId: 'proj1',
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.completed,
      );

      sensor = Sensor(
        sensorIndex: 0,
        sensorId: 's1',
        name: 'Accelerometer',
        timeStamp: DateTime.now(),
        localPath: '/tmp/sensor.csv',
      );

      fakeVideo = MockVideoController();
      when(() => fakeVideo.value).thenReturn(
        VideoPlayerValue(
          duration: const Duration(seconds: 60),
          position: const Duration(seconds: 20),
          isInitialized: true,
          isPlaying: false,
        ),
      );
      when(() => fakeVideo.play()).thenAnswer((_) async {});
      when(() => fakeVideo.pause()).thenAnswer((_) async {});
      when(() => fakeVideo.seekTo(any())).thenAnswer((_) async {});
      when(() => fakeVideo.setVolume(any())).thenAnswer((_) async {});
      when(() => fakeVideo.setPlaybackSpeed(any())).thenAnswer((_) async {});

      mockPlaybackController = MockPlaybackController();
      when(() => mockPlaybackController.renameRecording(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockPlaybackController.deleteRecording(any()))
          .thenAnswer((_) async {});
      when(() => mockPlaybackController.exportVideoFolder(any())).thenAnswer((_) async {});
    });

    testWidgets('Full playback page integration', (tester) async {
      final goRouter = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => Scaffold(
              appBar: PlaybackBar(vc: fakeVideo, recording: recording),
              body: Container(),
            ),
          ),
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const Scaffold(body: Center(child: Text('HOME'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStateProvider.overrideWith((ref) {
              final notifier = HomeStateNotifier();
              notifier.state =
                  HomeState.initial().copyWith(recordings: [recording]);
              return notifier;
            }),
            localMediaProvider.overrideWithValue(MockLocalMedia()),
            playbackControllerProvider.overrideWithValue(mockPlaybackController),
            videoPlayerControllerProvider(recording)
                .overrideWith((ref) async => fakeVideo),
            sensorSampleProvider(sensor.localPath).overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(routerConfig: goRouter),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlaybackBar), findsOneWidget);
      expect(find.text('IntegrationTestVideo'), findsOneWidget);
      expect(find.byType(PlaybackSpeedBadge), findsOneWidget);

      final volFinder = find.widgetWithIcon(IconButton, Icons.volume_up);
      expect(volFinder, findsOneWidget);
      final IconButton volWidget = tester.widget(volFinder);
      volWidget.onPressed?.call();
      await tester.pumpAndSettle();
      verify(() => fakeVideo.setVolume(0)).called(1);

      final pbFinder = find.byType(PlaybackSpeedBadge);
      expect(pbFinder, findsOneWidget);
      final inkFinder = find.descendant(of: pbFinder, matching: find.byType(InkWell));
      expect(inkFinder, findsOneWidget);
      final InkWell inkWidget = tester.widget(inkFinder);
      inkWidget.onTap?.call();
      await tester.pumpAndSettle();
      verify(() => fakeVideo.setPlaybackSpeed(0.5)).called(1);

      // sensor long-press
      final sensorToggleFinder = find.byWidgetPredicate((w) => w is IconButton && w.icon is Image);
      expect(sensorToggleFinder, findsOneWidget);
      final IconButton sensorBtn = tester.widget(sensorToggleFinder);
      sensorBtn.onLongPress?.call();
      await tester.pumpAndSettle();
      expect(find.text('No sensors available.'), findsOneWidget);

      final playFinder = find.widgetWithIcon(IconButton, Icons.play_arrow);
      final IconButton playBtn = tester.widget(playFinder);
      playBtn.onPressed?.call();
      await tester.pump();
      verify(() => fakeVideo.play()).called(1);

      final exportFinder = find.widgetWithText(TextButton, 'Export');
      final TextButton exportBtn = tester.widget(exportFinder);
      exportBtn.onPressed?.call();
      await tester.pumpAndSettle();
      verify(() => mockPlaybackController.exportVideoFolder(recording)).called(1);

      final delFinder = find.widgetWithText(TextButton, 'Delete');
      final TextButton delBtn = tester.widget(delFinder);
      delBtn.onPressed?.call();
      await tester.pumpAndSettle();
      verify(() => mockPlaybackController.deleteRecording(recording));
    });

    testWidgets('Sensor playback page integration', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localMediaProvider.overrideWithValue(MockLocalMedia()),
            videoPlayerControllerProvider(recording)
                .overrideWith((ref) async => fakeVideo),
            sensorSampleProvider(sensor.localPath).overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: SensorPlaybackBar(
                  vc: fakeVideo, recording: recording, sensorName: sensor.name),
              body: Container(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SensorPlaybackBar), findsOneWidget);
      expect(find.text('Accelerometer'), findsOneWidget);
    });

    testWidgets('RenameDialog shows and returns entered name', (tester) async {
      final completer = Completer<String?>();

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final res = await RenameDialog.show(context, oldName: 'OldName');
                  completer.complete(res);
                },
                child: const Text('OpenDialog'),
              ),
            ),
          );
        }),
      ));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      expect(find.text('Rename Video'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'NewName');
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      final result = await completer.future.timeout(const Duration(seconds: 1));
      expect(result, 'NewName');
    });

    testWidgets('AppBar controls full coverage', (tester) async {
      final pb = PlaybackNotifier();
      pb.setSelectedSensors([sensor]);

      final goRouter = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => Scaffold(
              appBar: PlaybackBar(vc: fakeVideo, recording: recording),
              body: Container(),
            ),
          ),
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const Scaffold(body: Center(child: Text('HOME'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStateProvider.overrideWith((ref) {
              final notifier = HomeStateNotifier();
              notifier.state = HomeState.initial().copyWith(recordings: [recording]);
              return notifier;
            }),
            localMediaProvider.overrideWithValue(MockLocalMedia()),
            playbackControllerProvider.overrideWithValue(mockPlaybackController),
            playbackProvider(recording.id).overrideWith((ref) => pb),
            videoPlayerControllerProvider(recording)
                .overrideWith((ref) async => fakeVideo),
            sensorSampleProvider(sensor.localPath).overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(routerConfig: goRouter),
        ),
      );

      await tester.pumpAndSettle();

      final sensorToggleFinder = find.byWidgetPredicate((w) => w is IconButton && w.icon is Image);
      expect(sensorToggleFinder, findsOneWidget);
      Image img = tester.widget<Image>(find.descendant(of: sensorToggleFinder, matching: find.byType(Image)));
      final initialAsset = (img.image as AssetImage).assetName;
      expect(initialAsset, 'assets/buttons/wave_sound_on.png');

      final IconButton sensorBtn = tester.widget(sensorToggleFinder);
      sensorBtn.onPressed?.call();
      await tester.pumpAndSettle();

      img = tester.widget<Image>(find.descendant(of: sensorToggleFinder, matching: find.byType(Image)));
      final afterAsset = (img.image as AssetImage).assetName;
      expect(afterAsset, 'assets/buttons/wave_sound.png');

      final rewindFinder = find.widgetWithIcon(IconButton, Icons.fast_rewind);
      expect(rewindFinder, findsOneWidget);
      final IconButton rewindBtn = tester.widget(rewindFinder);
      rewindBtn.onPressed?.call();
      await tester.pumpAndSettle();
      verify(() => fakeVideo.seekTo(const Duration(seconds: 10))).called(1);

      final ffFinder = find.widgetWithIcon(IconButton, Icons.fast_forward);
      expect(ffFinder, findsOneWidget);
      final IconButton ffBtn = tester.widget(ffFinder);
      ffBtn.onPressed?.call();
      await tester.pumpAndSettle();
      verify(() => fakeVideo.seekTo(const Duration(seconds: 30))).called(1);

      final backFinder = find.widgetWithIcon(IconButton, Icons.arrow_back_ios);
      final IconButton backBtn = tester.widget(backFinder);
      backBtn.onPressed?.call();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);

      final pauseFinder = find.widgetWithIcon(IconButton, Icons.pause);
      if (pauseFinder.evaluate().isNotEmpty) {
        final IconButton pauseBtn = tester.widget(pauseFinder);
        pauseBtn.onPressed?.call();
        await tester.pumpAndSettle();
        verify(() => fakeVideo.pause()).called(1);
      }
    });

    testWidgets('SelectSensorsDialog returns empty when no sensors available', (tester) async {
      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    await SelectSensorsDialog.show(context, available: []);
                  },
                  child: const Text('OpenDialog'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      expect(find.text('No sensors available.'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('No sensors available.'), findsNothing);
    });

    testWidgets('SelectSensorsDialog selection triggers onChanged and onLongPress and returns selection', (tester) async {
      final s1 = Sensor(sensorIndex: 0, sensorId: 's1', name: 'S1', timeStamp: DateTime.now(), localPath: '/tmp/s1');
      final s2 = Sensor(sensorIndex: 1, sensorId: 's2', name: 'S2', timeStamp: DateTime.now(), localPath: '/tmp/s2');

      List<Sensor>? lastChanged;
      Sensor? longPressed;

      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    await SelectSensorsDialog.show(
                      context,
                      available: [s1, s2],
                      initialSelected: [s1],
                      onChanged: (sel) => lastChanged = sel,
                      onLongPress: (item) => longPressed = item,
                    );
                  },
                  child: const Text('OpenDialog'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      // Ensure both sensors are visible
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);

      // Tap the ListTile for S2
      await tester.tap(find.widgetWithText(ListTile, 'S2'));
      await tester.pumpAndSettle();

      expect(lastChanged, isNotNull);
      expect(lastChanged!.first.sensorId, 's2');

      // Long press on second sensor via gesture
      await tester.longPress(find.text('S2'));
      await tester.pumpAndSettle();
      expect(longPressed, isNotNull);
      expect(longPressed!.sensorId, 's2');

      // Close dialog and ensure it's dismissed
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Select sensor'), findsNothing);
    });

    testWidgets('SelectSensorsDialog honors initialSelected (returns initialSelected)', (tester) async {
      final s1 = Sensor(sensorIndex: 0, sensorId: 's1', name: 'S1', timeStamp: DateTime.now(), localPath: '/tmp/s1');
      final s2 = Sensor(sensorIndex: 1, sensorId: 's2', name: 'S2', timeStamp: DateTime.now(), localPath: '/tmp/s2');

      final completer = Completer<List<Sensor>?>();

      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final res = await SelectSensorsDialog.show(
                      context,
                      available: [s1, s2],
                      initialSelected: [s2],
                    );
                    completer.complete(res);
                  },
                  child: const Text('OpenDialog'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      // Close dialog immediately; initialSelected should be returned
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final result = await completer.future.timeout(const Duration(seconds: 1));
      expect(result, isNotNull);
      expect(result!.first.sensorId, 's2');
    });

    testWidgets('SelectSensorsDialog list height is clamped when many sensors', (tester) async {
      final sensors = List.generate(10, (i) => Sensor(sensorIndex: i, sensorId: 's$i', name: 'S$i', timeStamp: DateTime.now(), localPath: '/tmp/s$i'));

      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    await SelectSensorsDialog.show(context, available: sensors);
                  },
                  child: const Text('OpenDialog'),
                ),
              ),
            ),
          ),
        ],
      );


      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final size = tester.getSize(listFinder);
      expect(size.height <= 240.0, isTrue);

      // Close dialog to avoid leaving it open
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('SelectSensorsDialog onChanged called for each selection change', (tester) async {
      final sensors = [
        Sensor(sensorIndex: 0, sensorId: 's0', name: 'S0', timeStamp: DateTime.now(), localPath: '/tmp/s0'),
        Sensor(sensorIndex: 1, sensorId: 's1', name: 'S1', timeStamp: DateTime.now(), localPath: '/tmp/s1'),
        Sensor(sensorIndex: 2, sensorId: 's2', name: 'S2', timeStamp: DateTime.now(), localPath: '/tmp/s2'),
      ];
      final changes = <String>[];

      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    await SelectSensorsDialog.show(
                      context,
                      available: sensors,
                      onChanged: (sel) => changes.add(sel.isEmpty ? 'none' : sel.first.sensorId),
                    );
                  },
                  child: const Text('OpenDialog'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

      await tester.tap(find.text('OpenDialog'));
      await tester.pumpAndSettle();

      // tap S0, S1, S2 by tapping the center of their ListTile areas to avoid ambiguous ancestor matches
      for (final s in sensors) {
        final tileFinder = find.widgetWithText(ListTile, s.name);
        expect(tileFinder, findsOneWidget);
        final center = tester.getCenter(tileFinder);
        await tester.tapAt(center);
        await tester.pumpAndSettle();
      }

      expect(changes.length, sensors.length);
      expect(changes, ['s0', 's1', 's2']);

      // Close dialog to avoid leaving it open
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}

