
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class PlaybackPage extends StatefulWidget {
  const PlaybackPage({super.key});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  VideoPlayerController? _controller;
  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";
  final GlobalKey _key = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  void initState() {
    super.initState();

    /// FORCE LANDSCAPE
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(file.path));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      controller.play();
    } catch (_) {
      // Handle error if needed
    }
  }

  void togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  void toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      isMuted = !isMuted;
      c.setVolume(isMuted ? 0 : 1);
    });
  }

  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);
    speed = clamped;
    speedString = "${clamped}x";
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      setState(() {});
      return;
    }
    c.setPlaybackSpeed(clamped);
    setState(() {});
  }
  void _seekBySeconds(int seconds) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final current = c.value.position;
    final total = c.value.duration;
    final newPos = current + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (total != null && newPos > total ? total : newPos);
    c.seekTo(clamped);
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {},
                color: Colors.black,
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/images/wave.png",
                  width: 24,
                  height: 24,
                ),
              ),

              IconButton(
                icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                onPressed: toggleMute,
                color: Colors.black,
              ),
              const SizedBox(width: 20),
              GestureDetector(
                key: _key,
                onTap: () => setSpeed(speed == 1.0 ? 0.5 : 1.0),
                onLongPress: () async {
                  final renderBox =
                      _key.currentContext!.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;

                  final selected = await showMenu<double>(
                    color: Colors.grey,
                    context: context,
                    position: RelativeRect.fromLTRB(
                      offset.dx,
                      offset.dy + size.height,
                      offset.dx + size.width,
                      offset.dy,
                    ),
                    items: const [
                      PopupMenuItem(value: 0.25, child: Text("0.25x")),
                      PopupMenuItem(value: 0.5, child: Text("0.5x")),
                      PopupMenuItem(value: 1.0, child: Text("1x")),
                      PopupMenuItem(value: 1.5, child: Text("1.5x")),
                      PopupMenuItem(value: 2.0, child: Text("2x")),
                    ],
                  );

                  if (selected != null) setSpeed(selected);
                },
                child: Text(
                  speedString,
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
              const SizedBox(width: 20),
              const Text("Name", style: TextStyle(color: Colors.black, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.fast_rewind),
                onPressed: () => _seekBySeconds(-10),
                color: Colors.black,
              ),
              IconButton(
                icon: Icon(
                  _controller?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: togglePlay,
                color: Colors.black,
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward),
                onPressed: () => _seekBySeconds(10),
                color: Colors.black,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text("Export", style: TextStyle(fontSize: 15)),
              ),
              PopupMenuButton<String>(
                color: Colors.white,
                onSelected: (_) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "Duplicate", child: Text('Duplicate')),
                  PopupMenuItem(value: "Rename", child: Text('Rename')),
                ],
                child: const Text("more", style: TextStyle(fontSize: 15, color: Colors.black)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Delete", style: TextStyle(fontSize: 15, color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(preferredSize: const Size.fromHeight(70), child: _buildTopBar()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _controller == null
                  ? Center(
                      child: ElevatedButton(
                        onPressed: pickVideo,
                        child: const Text("Video aus Galerie wählen"),
                      ),
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
            ),
            if (_controller != null)
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: Colors.red),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller?.dispose();
    super.dispose();
  }
}