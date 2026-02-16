import 'package:flutter/material.dart';
import '../controllers/sensor_repository.dart';

class ChartPainter extends CustomPainter {
  final List<SensorSample> samples;
  final int startMs;
  final int endMs;

  ChartPainter({
    required this.samples,
    required this.startMs,
    required this.endMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || endMs <= startMs) return;

    // Draw background grid
    final gridPaint = Paint()
      ..color = Colors.grey.withAlpha((0.20 * 255).round())
      ..strokeWidth = 1;

    for (int i = 0; i < 6; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Extract x/y/z and timestamps from typed SensorSample list
    final List<double> xVals = [];
    final List<double> yVals = [];
    final List<double> zVals = [];
    final List<int> timestamps = [];

    for (final s in samples) {
      xVals.add(s.x);
      yVals.add(s.y);
      zVals.add(s.z);
      timestamps.add(s.timestampMs);
    }

    if (timestamps.isEmpty) return;
    double minV = double.infinity;
    double maxV = -double.infinity;
    for (final v in [...xVals, ...yVals, ...zVals]) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    if ((maxV - minV).abs() < 1e-6) {
      maxV += 1;
      minV -= 1;
    }
    final padding = (maxV - minV) * 0.08;
    minV -= padding;
    maxV += padding;
    final double span = (endMs - startMs).toDouble();
    double tx(int t) => ((t - startMs) / span).clamp(0.0, 1.0) * size.width;
    double ty(double v) => size.height - ((v - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;

    const int stepMs = 30;
    List<int> resampleTimestamps(List<int> origTs) {
      final List<int> out = [];
      for (int t = startMs; t <= endMs; t += stepMs) out.add(t);
      return out;
    }

    List<double> interpSeries(List<int> origTs, List<double> origVals, List<int> targetTs) {
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
          final denim = (t1 - t0);
          final alpha = denim == 0 ? 0.0 : (t - t0) / denim;
          out[i] = v0 + (v1 - v0) * alpha;
        }
      }
      return out;
    }
    Path buildSmoothPathFromResampled(List<double> vals, List<int> rTs) {
      final path = Path();
      if (vals.isEmpty || rTs.isEmpty) return path;
      path.moveTo(tx(rTs.first), ty(vals.first));
      for (int i = 1; i < vals.length; i++) {
        final x1 = tx(rTs[i - 1]);
        final y1 = ty(vals[i - 1]);
        final x2 = tx(rTs[i]);
        final y2 = ty(vals[i]);
        final mx = (x1 + x2) / 2;
        final my = (y1 + y2) / 2;
        path.quadraticBezierTo(x1, y1, mx, my);
      }
      path.lineTo(tx(rTs.last), ty(vals.last));
      return path;
    }
    final resTs = resampleTimestamps(timestamps);
    final rx = interpSeries(timestamps, xVals, resTs);
    final ry = interpSeries(timestamps, yVals, resTs);
    final rz = interpSeries(timestamps, zVals, resTs);
    void paintAxisFromResampled(List<double> rvals, Color color) {
      if (rvals.isEmpty) return;
      final paint = Paint()
        ..color = color.withAlpha((0.9 * 255).round())
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      final p = buildSmoothPathFromResampled(rvals, resTs);
      canvas.drawPath(p, paint);
      final glow = Paint()
        ..color = color.withAlpha((0.12 * 255).round())
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      canvas.drawPath(p, glow);
    }

    paintAxisFromResampled(rx, Colors.blue);
    paintAxisFromResampled(ry, Colors.red);
    paintAxisFromResampled(rz, Colors.purple);
  }

  @override
  bool shouldRepaint(covariant ChartPainter old) {
    return old.samples.length != samples.length || old.startMs != startMs || old.endMs != endMs;
  }
}
