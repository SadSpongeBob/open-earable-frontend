import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

class PlaybackPage extends ConsumerStatefulWidget {
  final String? recordingId;

  const PlaybackPage({
    super.key,
    required this.recordingId,
  });

  @override
  ConsumerState<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends ConsumerState<PlaybackPage> {
  late final PlaybackController _controller;
  final GlobalKey _speedKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final id = widget.recordingId!;
    final cloud = id.startsWith("rcd_");
    _controller = ref.read(
      playbackControllerProvider(
        PlaybackArgs(
          recordingId: id,
          cloudVideo: cloud,
        ),
      ),
    );

    /// Load Video
    _controller.loadVideo().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = _controller.videoController;

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
                recordingId: widget.recordingId,
              ),
            ),

            Expanded(
              child: (vc == null || !vc.value.isInitialized)
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : VideoCard(controller: vc),
            ),
          ],
        ),
      ),
    );
  }
}
