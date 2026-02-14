import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/home/state/home_provider.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

class PlaybackPage extends ConsumerWidget {
  final String recordingId;
  final RecordingSource source;
  final Recording? recording;

  const PlaybackPage({
    super.key,
    required this.recordingId,
    required this.source,
    this.recording,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeStateProvider);

    final rec =
        recording ??
        home.videos.firstWhere(
          (r) => r.id == recordingId && r.source == source,
          orElse: () => throw Exception('Recording not found'),
        );
    final videoAsync = ref.watch(videoPlayerControllerProvider(rec));
    final speedKey = GlobalKey();

    return Scaffold(
      backgroundColor: AppColors.twoHundred,
      appBar: videoAsync.when(
        loading: () => null,
        error: (_, _) => null,
        data: (vc) => TopBar(vc: vc, speedKey: speedKey, recording: rec),
      ),
      body: videoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed to load video: $e")),
        data: (vc) => SafeArea(
          child: Center(
            child: VideoCard(controller: vc),
          ),
        ),
      ),
    );
  }
}
