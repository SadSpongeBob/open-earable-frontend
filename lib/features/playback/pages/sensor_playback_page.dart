import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/playback/widgets/sensor_chart.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/features/playback/widgets/playback_top_bar.dart';

class SensorPlaybackPage extends ConsumerStatefulWidget {
  final Sensor sensor;
  final VideoPlayerController videoController;
  final String recordingId;

  const SensorPlaybackPage({
    super.key,
    required this.sensor,
    required this.videoController,
    required this.recordingId,
  });

  @override
  ConsumerState<SensorPlaybackPage> createState() => _SensorPlaybackPageState();
}

class _SensorPlaybackPageState extends ConsumerState<SensorPlaybackPage> {
  @override
  Widget build(BuildContext context) {
    final vc = widget.videoController;

    return Scaffold(
      appBar: PlaybackTopBar(
        vc: vc,
        recordingId: widget.recordingId,
        minimal: true,
        title: widget.sensor.name,
        // when returning, don't pause the controller here; main playback page owns it
        onBack: () {
          if (context.mounted) context.pop();
        },
      ),
      body: SafeArea(
        child: Center(
          child: Consumer(
            builder: (context, ref, _) {
              final samplesAsync = ref.watch(sensorSampleProvider(widget.sensor.localPath));

              return samplesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler beim Laden der Sensoren: $e')),
                data: (samples) {
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            child: SensorChartWidget(
                              controller: vc,
                              samples: samples,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // progress indicator like in VideoCard
                          VideoProgressIndicator(
                            vc,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
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
    );
  }
}
