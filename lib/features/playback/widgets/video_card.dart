import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/playback/widgets/sensorchart.dart';
import 'package:video_player/video_player.dart';

import '../state/sensor_providers.dart';

class VideoCard extends StatelessWidget {
  final VideoPlayerController controller;
  final SensorRequest? sensorRequest;
  final bool showSensorChart;

  const VideoCard({required this.controller, this.sensorRequest, this.showSensorChart = true, super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      VideoPlayer(controller),
    ];

    final shouldShowChart = sensorRequest != null && showSensorChart;

    if (shouldShowChart) {
      children.add(Positioned(
        left: 0,
        right: 0,
        bottom: 20,
        height: 200,
        child: Consumer(builder: (context, ref2, _) {
          final sensorAsync = ref2.watch(sensorDataProvider(sensorRequest!));
          return sensorAsync.when(
            loading: () => Container(),
            error: (e, _) => Container(),
            data: (samples) => SensorChartWidget(
              controller: controller,
              samples: samples,
            ),
          );
        }),
      ));
    }

    // progress indicator stays at the bottom
    children.add(Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            children: children,
          ),
        ),
      ),
    );
  }
}
