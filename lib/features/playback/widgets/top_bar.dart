import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';
import 'package:openearable/features/playback/state/playback_state.dart';
import 'package:video_player/video_player.dart';
import '../../../app/routing/routes.dart';
import '../../../app/theme/app_bar_styles.dart';
import 'rename_dialog.dart';

class TopBar extends ConsumerWidget {
  final VideoPlayerController vc;
  final GlobalKey speedKey;
  final Recording recording;

  const TopBar({
    super.key,
    required this.vc,
    required this.speedKey,
    required this.recording,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeStateProvider);
    final current = ref.watch(
      homeStateProvider.select((home) {
        for (final r in home.recordings) {
          if (r.id == recording.id && r.source == recording.source) return r;
        }
        return recording;
      }),
    );

    final playbackState = ref.watch(playbackProvider(current.id));
    final playbackNotifier = ref.read(playbackProvider(current.id).notifier);

    vc.setVolume(playbackState.isMuted ? 0 : 1);
    vc.setPlaybackSpeed(playbackState.speed);

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
      final newName = await showRenameDialog(context, oldName: current.name);
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

    return SafeArea(
      child: Container(
        height: 88,
        decoration: GlobalAppBarStyles.appBarDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedBuilder(
            animation: vc,
            builder: (context, _) {
              final isPlaying = vc.value.isPlaying;

              final speedBadge = InkWell(
                key: speedKey,
                onTap: () => playbackNotifier.setSpeed(
                  playbackState.speed == 1.0 ? 0.5 : 1.0,
                ),
                onLongPress: () async {
                  final renderBox =
                      speedKey.currentContext!.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;

                  final selected = await showMenu<double>(
                    color: Colors.white,
                    context: context,
                    position: RelativeRect.fromLTRB(
                      offset.dx,
                      offset.dy + size.height,
                      offset.dx + size.width,
                      offset.dy,
                    ),
                    items: const [
                      PopupMenuItem(
                        value: 0.25,
                        child: Text(
                          "0.25x",
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ),
                      PopupMenuItem(
                        value: 0.5,
                        child: Text(
                          "0.5x",
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ),
                      PopupMenuItem(
                        value: 1.0,
                        child: Text(
                          "1x",
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ),
                      PopupMenuItem(
                        value: 1.5,
                        child: Text(
                          "1.5x",
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ),
                      PopupMenuItem(
                        value: 2.0,
                        child: Text(
                          "2x",
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ),
                    ],
                  );

                  if (selected != null) playbackNotifier.setSpeed(selected);
                },
                child: Text(
                  playbackState.speedString,
                  style: GlobalAppBarStyles.appBarBlackText,
                ),
              );

              return Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () async {
                            await vc.pause();
                            unawaited(controller.stopAndUpload(current));
                            if (context.mounted) context.go(Routes.home);
                          },
                          color: const Color(0xFFFF4442),
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/buttons/wave-sound.png',
                            width: 26,
                            height: 26,
                          ),
                          onPressed: () {},
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: Icon(
                            playbackState.isMuted
                                ? Icons.volume_off
                                : Icons.volume_up,
                          ),
                          onPressed: () => playbackNotifier.toggleMute(),
                          color: Colors.black87,
                          splashRadius: 20,
                        ),
                        speedBadge,
                        const SizedBox(width: 10),
                        Text(
                          current.name,
                          style: GlobalAppBarStyles.appBarBlackText,
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fast_rewind),
                        iconSize: 40,
                        onPressed: () => vc.seekTo(
                          vc.value.position - const Duration(seconds: 10),
                        ),
                        color: Colors.black87,
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        iconSize: 40,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => isPlaying ? vc.pause() : vc.play(),
                        color: Colors.black87,
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.fast_forward),
                        onPressed: () => vc.seekTo(
                          vc.value.position + const Duration(seconds: 10),
                        ),
                        color: Colors.black87,
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () =>
                              controller.exportVideoFolder(current),
                          child: const Text(
                            "Export",
                            style: GlobalAppBarStyles.appBarBlackText,
                          ),
                        ),
                        PopupMenuButton<String>(
                          color: Colors.white,
                          onSelected: (value) async {
                            if (value == "Rename") {
                              await doRename();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: "Rename",
                              child: Text(
                                'Rename',
                                style: GlobalAppBarStyles.appBarBlackText,
                              ),
                            ),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "More",
                              style: GlobalAppBarStyles.appBarBlackText,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await controller.deleteRecording(current);
                            if (context.mounted) context.go(Routes.home);
                          },
                          child: Text(
                            "Delete",
                            style: GlobalAppBarStyles.appBarSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
