import 'package:flutter_riverpod/legacy.dart';

class PlaybackState {
  final bool isMuted;
  final double speed;

  const PlaybackState({this.isMuted = false, this.speed = 1.0});

  String get speedString => "${speed}x";
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  void toggleMute() =>
      state = PlaybackState(isMuted: !state.isMuted, speed: state.speed);

  void setSpeed(double s) =>
      state = PlaybackState(isMuted: state.isMuted, speed: s.clamp(0.25, 2.0));
}

final playbackProvider = StateNotifierProvider.autoDispose
    .family<PlaybackNotifier, PlaybackState, String>(
      (ref, recordingId) => PlaybackNotifier(),
    );
