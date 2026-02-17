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
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  void toggleMute() =>
      state = PlaybackState(
        isMuted: !state.isMuted,
        speed: state.speed,
        selectedSensors: state.selectedSensors,
        showSensorChart: state.showSensorChart,
        availableSensors: state.availableSensors,
      );

  void setSpeed(double s) =>
      state = PlaybackState(
        isMuted: state.isMuted,
        speed: s.clamp(0.25, 2.0),
        selectedSensors: state.selectedSensors,
        showSensorChart: state.showSensorChart,
        availableSensors: state.availableSensors,
      );

  void setSelectedSensors(List<Sensor> sensors) =>
      state = PlaybackState(
        isMuted: state.isMuted,
        speed: state.speed,
        selectedSensors: List.unmodifiable(sensors),
        showSensorChart: state.showSensorChart,
        availableSensors: state.availableSensors,
      );

  void toggleShowSensorChart() =>
      state = PlaybackState(
        isMuted: state.isMuted,
        speed: state.speed,
        selectedSensors: state.selectedSensors,
        showSensorChart: !state.showSensorChart,
        availableSensors: state.availableSensors,
      );

  void setAvailableSensors(List<Sensor> sensors) =>
      state = PlaybackState(
        isMuted: state.isMuted,
        speed: state.speed,
        selectedSensors: state.selectedSensors,
        showSensorChart: state.showSensorChart,
        availableSensors: List.unmodifiable(sensors),
      );
}

final playbackProvider = StateNotifierProvider.autoDispose
    .family<PlaybackNotifier, PlaybackState, String>(
      (ref, recordingId) => PlaybackNotifier(),
    );
