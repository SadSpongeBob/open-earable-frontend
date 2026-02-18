import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/features/playback/state/playback_state.dart';
import 'package:openearable/features/playback/widgets/speed_badge.dart';
import 'package:video_player/video_player.dart';

class SensorPlaybackBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final VideoPlayerController vc;
  final Recording recording;
  final String sensorName;

  const SensorPlaybackBar({
    super.key,
    required this.vc,
    required this.recording,
    required this.sensorName,
  });

  @override
  ConsumerState<SensorPlaybackBar> createState() =>
      _SensorPlaybackBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _SensorPlaybackBarState extends ConsumerState<SensorPlaybackBar> {
  @override
  Widget build(BuildContext context) {
    final current = widget.recording;

    ref.listen<PlaybackState>(playbackProvider(current.id), (prev, next) {
      final prevMuted = prev?.isMuted;
      final prevSpeed = prev?.speed;

      if (prevMuted != next.isMuted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.vc.setVolume(next.isMuted ? 0 : 1);
        });
      }

      if (prevSpeed != next.speed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.vc.setPlaybackSpeed(next.speed);
        });
      }
    });

    final playbackState = ref.watch(playbackProvider(current.id));
    final playbackNotifier = ref.read(playbackProvider(current.id).notifier);

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      toolbarHeight: 88,
      elevation: 0,
      backgroundColor: Colors.transparent,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AppColors.fifty,
          boxShadow: [BoxShadow(color: AppColors.fiveHundred, blurRadius: 12)],
        ),
      ),
      title: AnimatedBuilder(
        animation: widget.vc,
        builder: (context, _) {
          final isPlaying = widget.vc.value.isPlaying;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // LEFT SIDE
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () async {
                          await widget.vc.pause();
                          if (context.mounted) context.pop();
                        },
                        color: AppColors.primary,
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: Icon(
                          playbackState.isMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                        ),
                        onPressed: () => playbackNotifier.toggleMute(),
                        color: AppColors.nineHundred,
                        splashRadius: 20,
                      ),
                      PlaybackSpeedBadge(
                        speed: playbackState.speed,
                        onSpeedChanged: playbackNotifier.setSpeed,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 300,
                        child: Text(
                          widget.sensorName,
                          style: AppTextStyles.footerRegular,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // CENTER CONTROLS
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fast_rewind),
                      iconSize: 40,
                      onPressed: () => widget.vc.seekTo(
                        widget.vc.value.position - const Duration(seconds: 10),
                      ),
                      color: AppColors.nineHundred,
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 40,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () =>
                          isPlaying ? widget.vc.pause() : widget.vc.play(),
                      color: AppColors.nineHundred,
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.fast_forward),
                      onPressed: () => widget.vc.seekTo(
                        widget.vc.value.position + const Duration(seconds: 10),
                      ),
                      color: AppColors.nineHundred,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
