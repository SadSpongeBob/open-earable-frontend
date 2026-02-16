import 'package:flutter_riverpod/legacy.dart';

class PlaybackState {
  final bool isMuted;
  final double speed;
  final List<String> selectedSensors;

  const PlaybackState({this.isMuted = false, this.speed = 1.0, this.selectedSensors = const []});

  String get speedString => "${speed}x";
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  void toggleMute() =>
      state = PlaybackState(isMuted: !state.isMuted, speed: state.speed, selectedSensors: state.selectedSensors);

  void setSpeed(double s) =>
      state = PlaybackState(isMuted: state.isMuted, speed: s.clamp(0.25, 2.0), selectedSensors: state.selectedSensors);

  void setSelectedSensors(List<String> sensors) =>
      state = PlaybackState(isMuted: state.isMuted, speed: state.speed, selectedSensors: List.unmodifiable(sensors));
}

final playbackProvider = StateNotifierProvider.autoDispose
    .family<PlaybackNotifier, PlaybackState, String>(
      (ref, recordingId) => PlaybackNotifier(),
    );
