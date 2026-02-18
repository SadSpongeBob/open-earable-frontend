import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/recording/sensor.dart';

class PlaybackState {
  final bool isMuted;
  final double speed;
  final List<Sensor> selectedSensors;
  final bool showSensorChart;
  final List<Sensor> availableSensors;

  const PlaybackState({
    this.isMuted = false,
    this.speed = 1.0,
    this.selectedSensors = const [],
    this.showSensorChart = true,
    this.availableSensors = const [],
  });

  String get speedString => "${speed}x";

  PlaybackState copyWith({
    bool? isMuted,
    double? speed,
    List<Sensor>? selectedSensors,
    bool? showSensorChart,
    List<Sensor>? availableSensors,
  }) {
    return PlaybackState(
      isMuted: isMuted ?? this.isMuted,
      speed: speed ?? this.speed,
      selectedSensors: selectedSensors ?? this.selectedSensors,
      showSensorChart: showSensorChart ?? this.showSensorChart,
      availableSensors: availableSensors ?? this.availableSensors,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);

  void setSpeed(double s) => state = state.copyWith(speed: s.clamp(0.25, 2.0));

  void setSelectedSensors(List<Sensor> sensors) =>
      state = state.copyWith(selectedSensors: List.unmodifiable(sensors));

  void toggleShowSensorChart() =>
      state = state.copyWith(showSensorChart: !state.showSensorChart);

  void setAvailableSensors(List<Sensor> sensors) =>
      state = state.copyWith(availableSensors: List.unmodifiable(sensors));
}

final playbackProvider = StateNotifierProvider.autoDispose
    .family<PlaybackNotifier, PlaybackState, String>(
      (ref, recordingId) => PlaybackNotifier(),
    );
