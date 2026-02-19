import '../../../api/services/recording/sensor_repository.dart';

/// Handles processing of sensor samples for charting purposes.
///
/// The controller takes a list of [SensorSample]s and allows:
/// - Extracting a window of samples for a given time range.
/// - Getting axis-specific values (X, Y, Z) for plotting.
/// - Smoothing data using a moving average.
///
/// Parameters:
/// - [samples]: The full list of sensor samples to process.
/// - [windowMs]: The size of the window in milliseconds for slicing data. Default is 8000ms.
class SensorChartController {
  final List<SensorSample> samples;
  final int windowMs;

  SensorChartController({required this.samples, this.windowMs = 8000});

  /// Returns a subset of [samples] that fall within a time window ending at [currentMs].
  ///
  /// The window is defined as [currentMs - windowMs] to [currentMs], clamped at zero.
  ///
  /// Parameters:
  /// - [currentMs]: The current timestamp in milliseconds.
  ///
  /// Returns:
  /// - A list of [SensorSample]s that are within the specified window.
  List<SensorSample> windowFor(int currentMs) {
    final start = (currentMs - windowMs).clamp(0, currentMs);
    return samples.where((s) => s.timestampMs >= start && s.timestampMs <= currentMs).toList();
  }

  /// Extracts a list of values for the specified axis ('X', 'Y', or 'Z') from the given samples.
  ///
  /// Parameters:
  /// - [list]: The list of [SensorSample]s to extract from.
  /// - [axis]: The axis to extract ('X', 'Y', or 'Z').
  ///
  /// Returns:
  /// - A list of double values corresponding to the specified axis.
  /// - Returns an empty list if the axis is invalid.
  List<double> axisValues(List<SensorSample> list, String axis) {
    switch (axis) {
      case 'X':
        return list.map((s) => s.x).toList();
      case 'Y':
        return list.map((s) => s.y).toList();
      case 'Z':
        return list.map((s) => s.z).toList();
      default:
        return [];
    }
  }

  /// Applies a simple moving average to smooth the input [values].
  ///
  /// Parameters:
  /// - [values]: The list of double values to smooth.
  /// - [window]: The number of points to use for the moving average.
  ///
  /// Returns:
  /// - A new list of smoothed values.
  /// - If the list has fewer points than [window], returns a copy of the original list.
  List<double> smooth(List<double> values, int window) {
    if (values.length <= window) return List.from(values);
    final out = <double>[];
    for (var i = 0; i < values.length; i++) {
      final s = (i - window).clamp(0, values.length - 1);
      double sum = 0;
      var cnt = 0;
      for (var j = s; j <= i; j++) {
        sum += values[j];
        cnt++;
      }
      out.add(sum / cnt);
    }
    return out;
  }
}
