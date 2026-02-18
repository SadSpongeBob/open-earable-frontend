import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'playback_top_bar.dart';
import 'package:openearable/api/models/recording/recording.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  final VideoPlayerController vc;
  final GlobalKey speedKey;
  final Recording recording;

  const TopBar({super.key, required this.vc, required this.speedKey, required this.recording});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlaybackTopBar(vc: vc, recording: recording);
  }
}
