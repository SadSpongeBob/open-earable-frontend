import 'package:flutter/material.dart';

/// A ChangeNotifier that manages the state of the sensor chart overlay
/// during recording and playback.
///
/// It keeps track of:
/// - The currently selected chart (by id)
/// - Whether the overlay is visible
///
/// The overlay should be shown only when a chart is selected and
/// the overlay visibility flag is enabled.
class RecordingChartProvider with ChangeNotifier {
  String? _activeChartId;

  bool _isOverlayVisible = true;

  /// The id of the currently active/selected chart.
  String? get activeChartId => _activeChartId;

  /// Whether the chart overlay is currently allowed to be visible.
  bool get isOverlayVisible => _isOverlayVisible;

  /// Toggles the selected chart.
  ///
  /// If the given [id] is already active, it will be unselected.
  /// Otherwise, the chart with the provided [id] becomes active.
  ///
  /// Notifies listeners so UI (e.g., overlays) can update accordingly.
  void toggleChart(String id) {
    if (_activeChartId == id) {
      // unselect
      _activeChartId = null;
    } else {
      // select new
      _activeChartId = id;
    }
    notifyListeners();
  }

  /// Toggles the visibility of the chart overlay without
  /// changing the currently selected chart.
  void toggleOverlayVisibility() {
    _isOverlayVisible = !_isOverlayVisible;
    notifyListeners();
  }

  /// Whether the overlay should be rendered.
  ///
  /// Returns true only when a chart is selected and the overlay
  /// visibility flag is enabled.
  bool get shouldShowOverlay =>
      _activeChartId != null && _isOverlayVisible;

  /// Clears the current chart selection and notifies listeners.
  void clear() {
    _activeChartId = null;
    notifyListeners();
  }
}
