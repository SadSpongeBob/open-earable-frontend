import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: videoAsync.when(
                loading: () => const SizedBox(height: 88),
                error: (_, _) => const SizedBox(height: 88),
                data: (vc) => TopBar(
                  vc: vc,
                  speedKey: speedKey,
                  recording: rec,
                ),
              ),
            ),
            Expanded(
              child: videoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text("Failed to load video: $e")),
                data: (vc) => VideoCard(controller: vc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
