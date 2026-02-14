import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoCard({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            children: [
              VideoPlayer(controller),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

