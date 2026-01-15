import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Einfacher Controller, der die Videoplayback-Logik kapselt.
class PlaybackController extends ChangeNotifier {
  VideoPlayerController? videoController;
  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";

  final ImagePicker _picker = ImagePicker();
  /// Öffnet die Galerie, um ein Video auszuwählen, und initialisiert den Videoplayer.
  /// to do hier mochte ich nur die funktionalitat sehen

  Future<void> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    await videoController?.dispose();
    final controller = VideoPlayerController.file(File(file.path));
    videoController = controller;

    try {
      await controller.initialize();
      controller.play();
      notifyListeners();
    } catch (_) {
      // Fto do
    }
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

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }
}
