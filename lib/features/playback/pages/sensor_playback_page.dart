import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/features/playback/widgets/failed_load_screen.dart';
import 'package:openearable/features/playback/widgets/sensor_chart_player.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/features/playback/widgets/sensor_playback_bar.dart';

/// A page for playback of recorded sensor data associated with a recording.
///
/// This page handles:
/// - Displaying the video playback of the recording via a [VideoPlayerController].
/// - Rendering sensor-specific data using [SensorChartPlayer].
/// - Showing a custom [SensorPlaybackBar] in the app bar with playback controls and sensor info.
/// - Loading sensor samples asynchronously via [sensorSampleProvider].
/// - Handling loading and error states for both the video controller and sensor data.
///
/// Parameters:
/// - [sensor]: The [Sensor] object representing the sensor data to visualize.
/// - [recording]: The [Recording] object that contains the video and sensor data.
class SensorPlaybackPage extends ConsumerStatefulWidget {
  final Sensor sensor;
  final Recording recording;

  const SensorPlaybackPage({
    super.key,
    required this.sensor,
    required this.recording,
  });

  @override
  ConsumerState<SensorPlaybackPage> createState() => _SensorPlaybackPageState();
}

class _SensorPlaybackPageState extends ConsumerState<SensorPlaybackPage> {
  @override
  Widget build(BuildContext context) {
    final videoControllerAsync = ref.watch(
      videoPlayerControllerProvider(widget.recording),
    );

    return videoControllerAsync.when(
      data: (vc) => Scaffold(
        appBar: SensorPlaybackBar(
          vc: vc,
          recording: widget.recording,
          sensorName: widget.sensor.name,
        ),
        body: SafeArea(
          child: Center(
            child: Consumer(
              builder: (context, ref, _) {
                final samplesAsync = ref.watch(
                  sensorSampleProvider(widget.sensor.localPath),
                );

                return samplesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Failed to load sensor information'),
                  ),
                  data: (samples) {
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(12),
                        color: AppColors.hundred,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: SensorChartPlayer(
                                controller: vc,
                                samples: samples,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // progress indicator like in VideoCard
                            VideoProgressIndicator(
                              vc,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.primary,
                                bufferedColor: AppColors.sixHundred,
                                backgroundColor: AppColors.fifty,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      error: (_, _) => FailedLoadScreen(
        errorMessage: 'Failed to load recording information',
        recording: widget.recording,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
