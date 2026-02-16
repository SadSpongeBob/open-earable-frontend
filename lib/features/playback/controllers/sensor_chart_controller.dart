import 'sensor_repository.dart';
class SensorChartController {
  final List<SensorSample> samples;
  final int windowMs;

  SensorChartController({required this.samples, this.windowMs = 8000});

  List<SensorSample> windowFor(int currentMs) {
    final start = (currentMs - windowMs).clamp(0, currentMs);
    return samples
        .where((s) => s.timestampMs >= start && s.timestampMs <= currentMs)
        .toList();
  }
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
