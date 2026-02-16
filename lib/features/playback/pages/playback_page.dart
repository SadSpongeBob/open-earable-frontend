import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/ui/popup_toast.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/network_status.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

class PlaybackPage extends ConsumerStatefulWidget {
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
  ConsumerState<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends ConsumerState<PlaybackPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;
      PopupToast.show(context, message: next.message);
      ref.read(toastProvider.notifier).state = null;
    });

    final home = ref.watch(homeStateProvider);

    final rec =
        widget.recording ??
            home.recordings.firstWhere(
                  (r) => r.id == widget.recordingId && r.source == widget.source,
              orElse: () => throw Exception('Recording not found'),
            );

    final videoAsync = ref.watch(videoPlayerControllerProvider(rec));
    final speedKey = GlobalKey();

    final net = ref.watch(networkStatusProvider);

    if (rec.isCloud) {
      final status = net.asData?.value;
      if (status == NetworkStatus.offline) {
        return Scaffold(
          backgroundColor: Colors.grey[200],
          body: SafeArea(
            child: Center(
              child: Text("You're offline. Connect to the internet to play this video."),
            ),
          ),
        );
      }
    }

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
                error: (e, _) => Center(child: Text("Failed to load video: $e")),
                data: (vc) => VideoCard(controller: vc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
