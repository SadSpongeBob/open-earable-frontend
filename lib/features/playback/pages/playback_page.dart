import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/ui/popup_toast.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/app_button.dart';
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
          backgroundColor: AppColors.twoHundred,
          body: _FailedLoadScreen(
            errorMessage:
                "You are offline. Connect to the internet to play this video.",
            recording: rec,
          ),
        );
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.twoHundred,
      appBar: videoAsync.when(
        loading: () => null,
        error: (_, _) => null,
        data: (vc) => TopBar(vc: vc, speedKey: speedKey, recording: rec),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: videoAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _FailedLoadScreen(
            errorMessage: "An error occurred. Please try again later.",
            recording: rec,
          ),
          data: (vc) => Center(child: VideoCard(controller: vc)),
        ),
      ),
    );
  }
}

class _FailedLoadScreen extends ConsumerWidget {
  const _FailedLoadScreen({
    required this.errorMessage,
    required this.recording,
  });

  final String errorMessage;
  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 400,
              child: Text(
                "You're offline. Connect to the internet to play this video.",
                style: AppTextStyles.subheaderMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 340,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton.danger(
                    text: 'Go Back',
                    onPressed: () => context.go(Routes.home),
                    fullWidth: false,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton.primary(
                      text: 'Retry',
                      onPressed: () {
                        ref.invalidate(networkStatusProvider);
                        ref.invalidate(
                          videoPlayerControllerProvider(recording),
                        );
                      },
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
