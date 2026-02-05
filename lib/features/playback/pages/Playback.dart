import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openearable/api/local_media.dart';
import '../../../api/services/recording/recording_service.dart';
import '../../home/state/home_provider.dart';
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
    final svc = ref.read(recordingServiceProvider);
    
    _controller = PlaybackController(localMedia: ref.read(localMediaProvider),
        recordingService: svc, recordingId: widget.recordingId!,
        cloudVideo: widget.recordingId!.startsWith("rcd_"));
   

    if (widget.recordingId!.isNotEmpty) {
      _controller.loadVideo();
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
                recordingId: widget.recordingId,
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final vc = _controller.videoController;

                  if (vc == null || !vc.value.isInitialized) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return VideoCard(controller: vc);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
