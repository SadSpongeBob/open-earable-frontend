import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/home_state.dart';
import 'package:openearable/features/playback/widgets/playback_bar.dart';
import 'package:openearable/features/playback/widgets/sensor_playback_bar.dart';
import 'package:openearable/features/playback/widgets/speed_badge.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/local_media.dart';

class RecordingFake extends Fake implements Recording {}

class MockLocalMedia extends Mock implements LocalMedia {}

class MockVideoController extends Mock
    implements VideoPlayerController, Listenable {
  @override
  void addListener(void Function()? listener) {}

  @override
  void removeListener(void Function()? listener) {}

  @override
  int get playerId => 0;

  int get textureId => 0;

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  VideoPlayerValue get value => VideoPlayerValue(
        duration: const Duration(seconds: 60),
        position: Duration.zero,
        isInitialized: true,
        isPlaying: false,
      );
}

class MockPlaybackController extends Mock implements PlaybackController {}

void main() {
  setUpAll(() {
    registerFallbackValue(RecordingFake());
  });

  group('Playback Integration Test', () {
    late Recording recording;
    late Sensor sensor;
    late VideoPlayerController fakeVideo;
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

      mockPlaybackController = MockPlaybackController();
      when(() => mockPlaybackController.renameRecording(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockPlaybackController.deleteRecording(any()))
          .thenAnswer((_) async {});
    });

    testWidgets('Full playback page integration', (tester) async {
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
          child: MaterialApp(
            home: Scaffold(
              appBar: PlaybackBar(vc: fakeVideo, recording: recording),
              body: Container(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlaybackBar), findsOneWidget);

      expect(find.text('IntegrationTestVideo'), findsOneWidget);
      expect(find.byType(PlaybackSpeedBadge), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(find.text('Rename Video'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'NewName');
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
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
  });
}