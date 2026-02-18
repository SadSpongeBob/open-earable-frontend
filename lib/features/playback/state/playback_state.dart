import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/recording/sensor.dart';

/// Represents the playback state for a recording.
///
/// Fields:
/// - [isMuted]: Whether audio is muted. Default `false`.
/// - [speed]: Playback speed multiplier. Default `1.0`.
/// - [selectedSensors]: List of sensors currently selected for charting. Default empty.
/// - [showSensorChart]: Whether to display the sensor chart. Default `true`.
/// - [availableSensors]: List of sensors available for this recording. Default empty.
///
/// Provides a convenient [copyWith] method for immutably updating state and
/// a [speedString] getter to display playback speed in UI.
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

  /// Playback speed as a string (e.g., "1.0x") for UI display.
  String get speedString => "${speed}x";

  /// Returns a copy of this [PlaybackState] with the provided values replaced.
  ///
  /// Parameters are optional; null values will retain the existing field values.
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

/// StateNotifier that manages playback state changes for a recording.
///
/// Responsibilities:
/// - Toggle mute/unmute audio.
/// - Adjust playback speed (clamped between 0.25x and 2.0x).
/// - Select and update sensors for chart visualization.
/// - Toggle visibility of the sensor chart.
/// - Update the list of available sensors.
class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier() : super(const PlaybackState());

  /// Toggles the audio mute state.
  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);

  /// Sets playback speed, clamped between 0.25x and 2.0x.
  ///
  /// Parameters:
  /// - [s]: Desired playback speed.
  void setSpeed(double s) => state = state.copyWith(speed: s.clamp(0.25, 2.0));

  /// Updates the list of selected sensors for charting.
  ///
  /// Parameters:
  /// - [sensors]: List of sensors to select. The list is stored as unmodifiable.
  void setSelectedSensors(List<Sensor> sensors) =>
      state = state.copyWith(selectedSensors: List.unmodifiable(sensors));

  /// Toggles the visibility of the sensor chart.
  void toggleShowSensorChart() =>
      state = state.copyWith(showSensorChart: !state.showSensorChart);

  /// Updates the list of available sensors for the recording.
  ///
  /// Parameters:
  /// - [sensors]: List of available sensors. Stored as unmodifiable.
  void setAvailableSensors(List<Sensor> sensors) =>
      state = state.copyWith(availableSensors: List.unmodifiable(sensors));
}

/// Provides a [PlaybackNotifier] instance for a specific recording.
final playbackProvider = StateNotifierProvider.autoDispose
    .family<PlaybackNotifier, PlaybackState, String>(
      (ref, recordingId) => PlaybackNotifier(),
    );
