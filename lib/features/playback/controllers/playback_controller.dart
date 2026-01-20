import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';


class PlaybackController extends ChangeNotifier {
  VideoPlayerController? videoController;
  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";
  Future<void> loadVideo(String path) async {
    if (path.isEmpty) return;

    await videoController?.dispose();

    final controller = VideoPlayerController.file(File(path));
    videoController = controller;
    await controller.initialize();
    controller.play();
    notifyListeners();

  }

  void togglePlay() {
    final c = videoController;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    notifyListeners();
  }

  void toggleMute() {
    final c = videoController;
    if (c == null) return;
    isMuted = !isMuted;
    c.setVolume(isMuted ? 0 : 1);
    notifyListeners();
  }

  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);
    speed = clamped;
    speedString = "${clamped}x";
    final c = videoController;
    if (c == null || !c.value.isInitialized) {
      notifyListeners();
      return;
    }
    c.setPlaybackSpeed(clamped);
    notifyListeners();
  }

  void seekBySeconds(int seconds) {
    final c = videoController;
    if (c == null || !c.value.isInitialized) return;
    final current = c.value.position;
    final total = c.value.duration;
    final newPos = current + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > total ? total : newPos);
    c.seekTo(clamped);
    notifyListeners();
  }
  Future<void> deleteVideo(String videoPath) async {
    final file = File(videoPath);
    final directory = file.parent;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
  String getVideoName(String path) {
    final fileName = File(path).uri.pathSegments.last;
    return fileName.split('.').first;
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }
}
