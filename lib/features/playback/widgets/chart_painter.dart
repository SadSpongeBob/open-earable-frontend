import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controllers/sensor_repository.dart';

class ChartPainter extends CustomPainter {
  final List<SensorSample> samples;
  final List<double> xVals;
  final List<double> yVals;
  final List<double> zVals;
  final int startMs;
  final int endMs;
  ChartPainter({
    required this.samples,
    required this.xVals,
    required this.yVals,
    required this.zVals,
    required this.startMs,
    required this.endMs,
  });
  double _safeMin(List<double> v) => v.isEmpty ? -1.0 : v.reduce((a, b) => a < b ? a : b);
  double _safeMax(List<double> v) => v.isEmpty ? 1.0 : v.reduce((a, b) => a > b ? a : b);
  void _drawCurve(Canvas canvas, Size size, List<double> vals, Color color) {
    if (vals.isEmpty || samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    final totalSpan = (endMs - startMs).toDouble();
    final minDraw = _safeMin(vals);
    final maxDraw = _safeMax(vals);

    double rangeRaw =
    (maxDraw - minDraw).abs() < 1e-6 ? 1.0 : (maxDraw - minDraw);
    final padding = rangeRaw * 0.15;

    final minV = minDraw - padding;
    final maxV = maxDraw + padding;

    final range = maxV - minV;
    for (var i = 0; i < vals.length; i++) {
      final t = (samples[i].timestampMs - startMs) / totalSpan;
      final x = t * size.width;

      final y = size.height - ((vals[i] - minV) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevT = (samples[i - 1].timestampMs - startMs) / totalSpan;
        final prevX = prevT * size.width;

        final prevY =
            size.height - ((vals[i - 1] - minV) / range) * size.height;

        final midX = (prevX + x) / 2;
        final midY = (prevY + y) / 2;

        path.quadraticBezierTo(prevX, prevY, midX, midY);
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || endMs <= startMs) return;

    final gridPaint = Paint()
      ..color = Colors.grey.withAlpha((0.2 * 255).round())
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _drawCurve(canvas, size, xVals, Colors.red);
    _drawCurve(canvas, size, yVals, Colors.black);
    _drawCurve(canvas, size, zVals, Colors.blue);
  }
  @override
  bool shouldRepaint(covariant ChartPainter old) =>
      old.samples != samples || old.startMs != startMs || old.endMs != endMs;
}
