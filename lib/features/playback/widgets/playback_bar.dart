import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/features/playback/state/playback_state.dart';
import 'package:openearable/features/playback/widgets/speed_badge.dart';
import 'package:video_player/video_player.dart';
import '../../../app/routing/routes.dart';
import 'rename_dialog.dart';
import 'select_sensors_dialog.dart';

/// A customizable playback bar displayed at the top of a Playback Page.
///
/// Displays the video title, playback controls, sensor chart toggles, and action buttons.
///
/// Parameters:
/// - [vc]: The [VideoPlayerController] controlling playback of the recording.
/// - [recording]: The [Recording] being played, used for title display and actions.
class PlaybackBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final VideoPlayerController vc;
  final Recording recording;

  const PlaybackBar({
    super.key,
    required this.vc,
    required this.recording,
  });

  @override
  ConsumerState<PlaybackBar> createState() => _PlaybackBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _PlaybackBarState extends ConsumerState<PlaybackBar> {
  /// Builds the playback bar UI.
  ///
  /// Layout:
  /// - **Left**: Back button, sensor toggle, mute/unmute, playback speed badge, recording name.
  /// - **Center**: Playback controls (rewind, play/pause, fast forward).
  /// - **Right**: Recording actions (Export, Rename, Delete).
  ///
  /// Behavior:
  /// - Listens to [PlaybackState] changes and updates the [VideoPlayerController] volume and speed.
  /// - Long-pressing the sensor button opens [SelectSensorsDialog] to manage sensor selection.
  /// - Rename and Delete buttons trigger respective [PlaybackController] operations.
  /// - Export button triggers [PlaybackController.exportVideoFolder] for the current recording.
  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeStateProvider);
    final current = ref.watch(
      homeStateProvider.select((home) {
        for (final r in home.recordings) {
          if (r.id == widget.recording.id &&
              r.source == widget.recording.source) {
            return r;
          }
        }
        return widget.recording;
      }),
    );

    ref.listen<PlaybackState>(playbackProvider(current.id), (prev, next) {
      final prevMuted = prev?.isMuted;
      final prevSpeed = prev?.speed;

      if (prevMuted != next.isMuted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Update volume when mute state changes
          widget.vc.setVolume(next.isMuted ? 0 : 1);
        });
      }

      if (prevSpeed != next.speed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Update playback speed when it changes in state
          widget.vc.setPlaybackSpeed(next.speed);
        });
      }
    });

    final playbackState = ref.watch(playbackProvider(current.id));
    final availableSensors = ref.watch(
      playbackProvider(current.id).select((s) => s.availableSensors),
    );
    final playbackNotifier = ref.read(playbackProvider(current.id).notifier);

    final controller = ref.read(playbackControllerProvider);

    // Validate new recording name before renaming
    bool nameExistsInSameProject(String name) {
      return home.recordings.any(
        (r) =>
            r.projectId == current.projectId &&
            r.name == name &&
            !(r.id == current.id && r.source == current.source),
      );
    }

    Future<void> doRename() async {
      final newName = await RenameDialog.show(context, oldName: current.name);
      if (newName == null || newName.trim().isEmpty) return;

      final trimmed = newName.trim();

      if (nameExistsInSameProject(trimmed)) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('video name exists')));
        }
        return;
      }

      await controller.renameRecording(current, trimmed);
    }

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
            boxShadow: [BoxShadow(color: AppColors.fiveHundred, blurRadius: 12)]
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
                          if (context.mounted) context.go(Routes.home);
                        },
                        color: AppColors.primary,
                        splashRadius: 20,
                      ),

                      IconButton(
                        icon: Image.asset(
                          playbackState.selectedSensors.isEmpty ||
                                  !playbackState.showSensorChart
                              ? 'assets/buttons/wave_sound.png'
                              : 'assets/buttons/wave_sound_on.png',
                          width: 26,
                          height: 26,
                        ),
                        onLongPress: () async {
                          if (!context.mounted) return;
                          final result = await SelectSensorsDialog.show(
                            context,
                            available: availableSensors,
                            initialSelected: playbackState.selectedSensors,
                            onChanged: (selected) =>
                                playbackNotifier.setSelectedSensors(selected),
                            onLongPress: (item) => context.push(
                              Routes.sensorPlayback,
                              extra: {
                                'recording': widget.recording,
                                'sensor': item,
                              },
                            ),
                          );
                          if (result != null) {
                            playbackNotifier.setSelectedSensors(result);
                          }
                        },
                        onPressed: () =>
                            playbackNotifier.toggleShowSensorChart(),
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
                          current.name,
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
                      // Seek backward/forward by 10 seconds
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

                // RIGHT SIDE
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => controller.exportVideoFolder(current),
                        child: const Text(
                          "Export",
                          style: AppTextStyles.footerRegular,
                        ),
                      ),
                      TextButton(
                        onPressed: doRename,
                        child: const Text(
                          "Rename",
                          style: AppTextStyles.footerRegular,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await controller.deleteRecording(current);
                          if (context.mounted) context.go(Routes.home);
                        },
                        child: Text(
                          "Delete",
                          style: AppTextStyles.footerBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
