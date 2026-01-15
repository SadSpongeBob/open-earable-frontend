import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

class PlaybackPage extends StatefulWidget {
  const PlaybackPage({super.key});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final PlaybackController _controller = PlaybackController();
  final GlobalKey _speedKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // FORCE LANDSCAPE
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(preferredSize: const Size.fromHeight(88), child: TopBar(controller: _controller, speedKey: _speedKey)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final vc = _controller.videoController;
                  if (vc == null) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: _controller.pickVideo,
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Video aus Galerie wählen", style: TextStyle(fontSize: 15)),
                      ),
                    );
                  }

                  if (!vc.value.isInitialized) return const SizedBox.shrink();

                  return VideoCard(controller: vc);
                },
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final vc = _controller.videoController;
                if (vc == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: VideoProgressIndicator(vc, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.red)),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

