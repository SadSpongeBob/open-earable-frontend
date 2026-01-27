import 'package:flutter/material.dart';

class RecordingChartProvider with ChangeNotifier {
  String? _activeChartId;

  String? get activeChartId => _activeChartId;

  void selectChart(String id) {
    _activeChartId = id;
    notifyListeners();
  }

  void clear() {
    _activeChartId = null;
    notifyListeners();
  }
}