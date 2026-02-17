import 'package:flutter/material.dart';

class RecordingChartProvider with ChangeNotifier {
  String? _activeChartId;

  bool _isOverlayVisible = true;

  String? get activeChartId => _activeChartId;
  bool get isOverlayVisible => _isOverlayVisible;

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

  void toggleOverlayVisibility() {
    _isOverlayVisible = !_isOverlayVisible;
    notifyListeners();
  }

  bool get shouldShowOverlay =>
      _activeChartId != null && _isOverlayVisible;

  void clear() {
    _activeChartId = null;
    notifyListeners();
  }
}
