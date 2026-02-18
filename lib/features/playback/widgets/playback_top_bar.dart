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

/// Reusable top bar used by PlaybackPage and SensorPlaybackPage.
/// Accepts either a [recording] object or a [recordingId] string (one of them must be provided).
class PlaybackTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final VideoPlayerController vc;
  final Recording? recording;
  final String? recordingId;
  final VoidCallback? onBack;
  final bool minimal;
  final String? title;

  const PlaybackTopBar({
    super.key,
    required this.vc,
    this.recording,
    this.recordingId,
    this.onBack,
    this.minimal = false,
    this.title,
  });

  String _resolveId(WidgetRef ref) {
    if (recording != null) return recording!.id;
    if (recordingId != null) return recordingId!;
    final home = ref.read(homeStateProvider);
    if (home.recordings.isNotEmpty) return home.recordings.first.id;
    return '';
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeStateProvider);
    final id = _resolveId(ref);

    // determine current Recording safely
    Recording current;
    if (recording != null) {
      current = ref.watch(homeStateProvider.select((h) {
        for (final r in h.recordings) {
          if (r.id == recording!.id && r.source == recording!.source) return r;
        }
        return recording!;
      }));
    } else if (id.isNotEmpty) {
      current = ref.watch(homeStateProvider.select((h) {
        for (final r in h.recordings) {
          if (r.id == id) return r;
        }
        return h.recordings.isNotEmpty ? h.recordings.first : Recording(
          id: '',
          name: '',
          source: RecordingSource.local,
          videoTimestamp: DateTime.now().toUtc(),
          uploadStatus: UploadStatus.pending,
        );
      }));
    } else {
      current = Recording(
        id: '',
        name: '',
        source: RecordingSource.local,
        videoTimestamp: DateTime.now().toUtc(),
        uploadStatus: UploadStatus.pending,
      );
    }

    ref.listen<PlaybackState>(playbackProvider(current.id), (prev, next) {
      final prevMuted = prev?.isMuted;
      final prevSpeed = prev?.speed;

      if (prevMuted != next.isMuted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          vc.setVolume(next.isMuted ? 0 : 1);
        });
      }

      if (prevSpeed != next.speed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          vc.setPlaybackSpeed(next.speed);
        });
      }
    });

    final playbackState = ref.watch(playbackProvider(current.id));
    final availableSensors = ref.watch(
      playbackProvider(current.id).select((s) => s.availableSensors),
    );
    final playbackNotifier = ref.read(playbackProvider(current.id).notifier);
    final controller = ref.read(playbackControllerProvider);

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

    Widget actionButton({required Widget icon, required VoidCallback onPressed, double? iconSize}) {
      return IconButton(
        icon: icon,
        iconSize: iconSize ?? 24,
        onPressed: onPressed,
        color: AppColors.nineHundred,
        splashRadius: 20,
      );
    }

    // decide if we should render the compact minimal bar
    // if a title is passed explicitly, prefer the minimal layout (sensor pages pass title)
    final useMinimal = minimal || (title != null);

    Widget leftSection() {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            actionButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (onBack != null) {
                  onBack!();
                  return;
                }

                await vc.pause();
                if (context.mounted) context.go(Routes.home);
              },
            ),
            IconButton(
              icon: Image.asset(
                playbackState.selectedSensors.isEmpty || !playbackState.showSensorChart
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
                  onChanged: (selected) => playbackNotifier.setSelectedSensors(selected),
                  onLongPress: (item) => context.push(
                    Routes.sensorPlayback,
                    extra: {'sensor': item, 'recording': current},
                  ),
                );
                if (result != null) playbackNotifier.setSelectedSensors(result);
              },
              onPressed: () => playbackNotifier.toggleShowSensorChart(),
              splashRadius: 20,
            ),
            actionButton(
              icon: Icon(playbackState.isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: () => playbackNotifier.toggleMute(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlaybackSpeedBadge(
                speed: playbackState.speed,
                onSpeedChanged: playbackNotifier.setSpeed,
              ),
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
      );
    }

    // Minimal left section: back + speed badge only
    Widget leftSectionMinimal() {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            actionButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (onBack != null) {
                  onBack!();
                  return;
                }

                await vc.pause();
                if (context.mounted) context.go(Routes.home);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlaybackSpeedBadge(
                speed: playbackState.speed,
                onSpeedChanged: playbackNotifier.setSpeed,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      );
    }
    ///TODO 1000 is hardcoded fix it i have to go hhhh

    Widget titleWidget() {
      final text = title ?? current.name;
      return Align(
        child: SizedBox(
        width: 1000,
        child: Text(
          text,
          style: AppTextStyles.footerRegular,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      );
    }

    Widget centerControls() {
      final isPlaying = vc.value.isPlaying;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            actionButton(
              icon: const Icon(Icons.fast_rewind),
              iconSize: 40,
              onPressed: () => vc.seekTo(vc.value.position - const Duration(seconds: 10)),
            ),
            const SizedBox(width: 8),
            actionButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 40,
              onPressed: () => isPlaying ? vc.pause() : vc.play(),
            ),
            const SizedBox(width: 8),
            actionButton(
              icon: const Icon(Icons.fast_forward),
              iconSize: 40,
              onPressed: () => vc.seekTo(vc.value.position + const Duration(seconds: 10)),
            ),
          ],
        ),
      );
    }

    Widget rightSection() {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => controller.exportVideoFolder(current),
              child: const Text("Export", style: AppTextStyles.footerRegular),
            ),
            TextButton(onPressed: doRename, child: const Text("Rename", style: AppTextStyles.footerRegular)),
            TextButton(
              onPressed: () async {
                await controller.deleteRecording(current);
                if (context.mounted) context.go(Routes.home);
              },
              child: Text(
                "Delete",
                style: AppTextStyles.footerBold.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
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
          boxShadow: [
            BoxShadow(color: AppColors.nineHundred.withAlpha((0.15 * 255).round()), blurRadius: 12),
          ],
        ),
      ),
      title: AnimatedBuilder(
        animation: vc,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (useMinimal) leftSectionMinimal() else leftSection(),
                Positioned.fill(child: Align(alignment: Alignment.center, child: centerControls())),
                if (!useMinimal) rightSection(),
                if (useMinimal) titleWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
