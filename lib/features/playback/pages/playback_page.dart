import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/ui/popup_toast.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/api/local_media.dart';

import 'package:openearable/features/home/state/home_provider.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';
import '../state/sensor_providers.dart';
import '../state/playback_state.dart';

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
    final playbackState = ref.watch(playbackProvider(rec.id));
    final videoAsync = ref.watch(videoPlayerControllerProvider(rec));

    final speedKey = GlobalKey();
    final String? selectedSensor = playbackState.selectedSensors.isNotEmpty
        ? playbackState.selectedSensors.first
        : null;

    final SensorRequest? sensorRequest = selectedSensor == null
        ? null
        : SensorRequest(
            projectId: rec.projectId ?? LocalMedia.defaultProjectId,
            recordingId: rec.id,
            sensorId: selectedSensor,
          );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: videoAsync.when(
                loading: () => const SizedBox(height: 88),
                error: (_, __) => const SizedBox(height: 88),
                data: (vc) => TopBar(vc: vc, speedKey: speedKey, recording: rec),
              ),
            ),
            Expanded(
              child: videoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(child: Text("Failed to load video: $e")),
                data: (vc) => Column(
                  children: [
                    Expanded(child: VideoCard(controller: vc, sensorRequest: sensorRequest, showSensorChart: playbackState.showSensorChart)),
                  ],
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}