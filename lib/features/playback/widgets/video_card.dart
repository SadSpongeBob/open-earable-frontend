import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:openearable/features/playback/widgets/sensor_chart_player.dart';
import 'package:video_player/video_player.dart';

/// A video card with optional sensor visualization and playback controls.
///
/// Parameters:
/// - [controller]: The [VideoPlayerController] for controlling video playback.
/// - [sensorPath]: Optional path to sensor data for overlaying a chart.
/// - [showSensorChart]: Whether to show the sensor chart overlay (default: true).
///
/// Behavior:
/// - Shows the video in a card with rounded corners and elevation.
/// - If [sensorPath] is provided and [showSensorChart] is true, overlays
///   a [SensorChartPlayer] at the bottom of the video.
/// - Displays a scrubbable [VideoProgressIndicator] at the bottom of the card.
/// - Uses a [Stack] to layer the video, sensor chart, and progress indicator.
class VideoCard extends StatelessWidget {
  final VideoPlayerController controller;
  final String? sensorPath;
  final bool showSensorChart;

  const VideoCard({
    required this.controller,
    this.sensorPath,
    this.showSensorChart = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Add video player as base layer
    final children = <Widget>[
      VideoPlayer(controller),
    ];

    final shouldShowChart = sensorPath != null && showSensorChart;

    // Overlay sensor chart if available
    if (shouldShowChart) {
      children.add(
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          height: 200,
          child: Consumer(
            builder: (context, ref, _) {
              final sensorAsync = ref.watch(sensorSampleProvider(sensorPath!));
              return sensorAsync.when(
                loading: () => Container(),
                error: (e, _) => Container(),
                data: (samples) =>
                    SensorChartPlayer(controller: controller, samples: samples),
              );
            },
          ),
        ),
      );
    }

    // Add progress indicator at the bottom
    children.add(
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: AppColors.sixHundred,
              backgroundColor: AppColors.fifty,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(children: children),
        ),
      ),
    );
  }
}
