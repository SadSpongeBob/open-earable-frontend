import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:openearable/app/theme/appBar_styles.dart';
import 'package:openearable/features/recordings/pages/recordings_page.dart';
import '../controllers/playback_controller.dart';

class TopBar extends StatelessWidget {
  final PlaybackController controller;
  final GlobalKey speedKey;
  final String videoPath;
  const TopBar({required this.controller, required this.speedKey,required this.videoPath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 88,
        decoration: GlobalAppBarStyles.appBarDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final vc = controller.videoController;
              final isPlaying = vc?.value.isPlaying == true;

              final speedBadge = InkWell(
                key: speedKey,
                onTap: () => controller.setSpeed(controller.speed == 1.0 ? 0.5 : 1.0),
                onLongPress: () async {
                  final renderBox = speedKey.currentContext!.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;
                  final selected = await showMenu<double>(
                    color: Colors.grey[200],
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
                  if (selected != null) controller.setSpeed(selected);
                },
                child: Text(controller.speedString, style: const TextStyle(fontSize: 20, color: Colors.black87)),

              );

              final left = Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {},
                  color: Colors.black87,
                  splashRadius: 20,
                ),
                const SizedBox(width: 6),
                Image.asset("assets/images/wave.png", width: 26, height: 26),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(controller.isMuted ? Icons.volume_off : Icons.volume_up),
                  onPressed: controller.toggleMute,
                  color: Colors.black87,
                  splashRadius: 20,
                ),
                const SizedBox(width: 8),
                speedBadge,
                const SizedBox(width: 12),
                Text(controller.getVideoName(videoPath), style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
              ]);

              final centerControls = Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  iconSize: 40,
                  onPressed: () => controller.seekBySeconds(-10),
                  color: Colors.black87,
                  splashRadius: 20,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 40,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),

                  onPressed: controller.togglePlay,
                  color: Colors.black87,
                  splashRadius: 28,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.fast_forward),
                  onPressed: () => controller.seekBySeconds(10),
                  color: Colors.black87,
                  splashRadius: 20,
                ),
              ]);

              final right = Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: () {
                  Gal.putVideo(videoPath);
                }, child: const Text("Export", style: TextStyle(fontSize: 20))),
                PopupMenuButton<String>(
                  color: Colors.white,
                  onSelected: (_) {},
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: "Duplicate", child: Text('Duplicate')),
                    PopupMenuItem(value: "Rename", child: Text('Rename')),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("more", style: TextStyle(fontSize: 20, color: Colors.black87)),
                  ),
                ),
                TextButton(onPressed: () {
                  controller.deleteVideo(videoPath);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => RecordingPage()),
                  );

                }, child: const Text("Delete", style: GlobalAppBarStyles.appBarText)),
              ]);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Align(alignment: Alignment.centerLeft, child: left),
                  centerControls,
                  Align(alignment: Alignment.centerRight, child: right),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

