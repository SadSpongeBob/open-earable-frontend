import '../../../api/services/recording/sensor_repository.dart';

/// Prepared data for the chart: resampled timestamps and axis series.
class ChartData {
  final List<int> resTs;
  final List<double> rx;
  final List<double> ry;
  final List<double> rz;
  final double minV;
  final double maxV;

  ChartData({
    required this.resTs,
    required this.rx,
    required this.ry,
    required this.rz,
    required this.minV,
    required this.maxV,
  });
  static ChartData fromSamples(
      List<SensorSample> samples,
      int startMs,
      int endMs, {
        int stepMs = 30,
        double defaultMinV = -1,
        double defaultMaxV = 1,
        double paddingRatio = 0.08,
        double epsilon = 1e-6,
      }) {
    final ts = <int>[];
    final x = <double>[];
    final y = <double>[];
    final z = <double>[];

    for (final s in samples) {
      if (s.timestampMs < startMs || s.timestampMs > endMs) continue;
      ts.add(s.timestampMs);
      x.add(s.x);
      y.add(s.y);
      z.add(s.z);
    }
    if (ts.isEmpty) {
      return ChartData(
        resTs: [],
        rx: [],
        ry: [],
        rz: [],
        minV: defaultMinV,
        maxV: defaultMaxV,
      );
    }
    final rTs = [for (int t = startMs; t <= endMs; t += stepMs) t];
    List<double> interp(List<int> origTs, List<double> origVals, List<int> targetTs) {
      final out = List<double>.filled(targetTs.length, 0);
      if (origTs.isEmpty) return out;
      int j = 0;
      for (int i = 0; i < targetTs.length; i++) {
        final t = targetTs[i];
        while (j < origTs.length - 2 && origTs[j + 1] < t) j++;
        if (t <= origTs.first) {
          out[i] = origVals.first;
        } else if (t >= origTs.last) {
          out[i] = origVals.last;
        } else {
          final t0 = origTs[j];
          final t1 = origTs[j + 1];
          final v0 = origVals[j];
          final v1 = origVals[j + 1];
          final denom = (t1 - t0);
          final alpha = denom == 0 ? 0.0 : (t - t0) / denom;
          out[i] = v0 + (v1 - v0) * alpha;
        }
      }
      return out;
    }

    final rx = interp(ts, x, rTs);
    final ry = interp(ts, y, rTs);
    final rz = interp(ts, z, rTs);

    // Compute min/max
    double minV = double.infinity;
    double maxV = -double.infinity;
    for (final v in [...rx, ...ry, ...rz]) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    if ((maxV - minV).abs() < epsilon) {
      maxV = minV + 1;
      minV = minV - 1;
    }

    final padding = (maxV - minV) * paddingRatio;
    minV -= padding;
    maxV += padding;

    return ChartData(resTs: rTs, rx: rx, ry: ry, rz: rz, minV: minV, maxV: maxV);
  }
}
