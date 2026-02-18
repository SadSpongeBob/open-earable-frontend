import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/services/user/user_preference_storage.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/ui/popup_toast.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/app/constants/colors.dart';

import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/network_status.dart';
import 'package:openearable/features/playback/widgets/failed_load_screen.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';
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
  void dispose() {
    if (widget.recording != null) {
      ref.invalidate(videoPlayerControllerProvider(widget.recording!));
    }
    super.dispose();
  }

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

    final net = ref.watch(networkStatusProvider);
    final wifiOnlyAsync = ref.watch(wifiOnlyProvider);

    if (rec.isCloud) {
      final status = net.asData?.value;
      if (status == NetworkStatus.offline) {
        return Scaffold(
          backgroundColor: AppColors.twoHundred,
          body: FailedLoadScreen(
            errorMessage:
                "You are offline. Connect to the internet to play this video.",
            recording: rec,
          ),
        );
      }

      return wifiOnlyAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.twoHundred,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, _) => Scaffold(
          backgroundColor: AppColors.twoHundred,
          body: FailedLoadScreen(
            errorMessage: "Failed to load preferences.",
            recording: rec,
          ),
        ),
        data: (wifiOnly) {
          if (status != null && !status.shouldUpload(wifiOnly)) {
            return Scaffold(
              backgroundColor: AppColors.twoHundred,
              body: FailedLoadScreen(
                errorMessage:
                    "You are using mobile data. Either switch to wifi or change your preferences in settings.",
                recording: rec,
              ),
            );
          }

          return _PlaybackVideoScaffold(recording: rec);
        },
      );
    }

    return _PlaybackVideoScaffold(recording: rec);
  }
}

class _PlaybackVideoScaffold extends ConsumerWidget {
  const _PlaybackVideoScaffold({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider(recording.id));
    final videoAsync = ref.watch(videoPlayerControllerProvider(recording));

    final speedKey = GlobalKey();

    // Selected Sensor
    final Sensor? selectedSensor = playbackState.selectedSensors.isNotEmpty
        ? playbackState.selectedSensors.first
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.twoHundred,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: videoAsync.when(
          loading: () => const SizedBox(height: 88),
          error: (_, _) => const SizedBox(height: 88),
          data: (vc) =>
              TopBar(vc: vc, speedKey: speedKey, recording: recording),
        ),
      ),

      body: SafeArea(
        child: videoAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),

          error: (e, _) => Center(
            child: Text(
              "Failed to load video: $e",
              style: AppTextStyles.subheaderMedium,
            ),
          ),

          data: (vc) => Center(
            child: Column(
              children: [
                Expanded(
                  child: VideoCard(
                    controller: vc,
                    sensorPath: selectedSensor?.localPath,
                    showSensorChart: playbackState.showSensorChart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
