import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatelessWidget {
  final VideoPlayerController controller;
  const VideoCard({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
      ),
    );
  }
}

