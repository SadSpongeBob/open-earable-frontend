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

    if (videoController == null || !videoController!.value.isInitialized) return;
    if (videoController!.value.isPlaying) {
      videoController?.pause();
    } else {
      videoController?.play();
    }
    notifyListeners();
  }

  void toggleMute() {
    if (videoController == null) return;
    isMuted = !isMuted;
    videoController?.setVolume(isMuted ? 0 : 1);
    notifyListeners();
  }

  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);
    speed = clamped;
    speedString = "${clamped}x";
    if (videoController == null || !videoController!.value.isInitialized) {
      notifyListeners();
      return;
    }
    videoController?.setPlaybackSpeed(clamped);
    notifyListeners();
  }

  void seekBySeconds(int seconds) {
    if (videoController == null || !videoController!.value.isInitialized) return;
    final current = videoController?.value.position;
    final total = videoController?.value.duration;
    final newPos = current! + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > total! ? total : newPos);
    videoController?.seekTo(clamped);
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
