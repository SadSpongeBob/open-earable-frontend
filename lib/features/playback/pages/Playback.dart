import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

class PlaybackPage extends StatefulWidget {
  final String videoPath;
  const PlaybackPage({super.key, required this.videoPath});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final PlaybackController _controller = PlaybackController();
  final GlobalKey _speedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.isNotEmpty) {
      _controller.loadVideo(widget.videoPath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: TopBar(
                controller: _controller,
                speedKey: _speedKey,
                videoPath: widget.videoPath,
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final vc = _controller.videoController;
                  if (vc == null || !vc.value.isInitialized) {
                    return const Center(
                    );
                  }
                  return VideoCard(controller: vc);
                },
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final vc = _controller.videoController;
                if (vc == null || !vc.value.isInitialized) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: VideoProgressIndicator(
                    vc,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(playedColor: Colors.red),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}
