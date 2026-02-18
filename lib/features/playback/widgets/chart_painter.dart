import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import '../controllers/chart_data.dart';

class ChartPainter extends CustomPainter {
  final ChartData data;
  final int startMs;
  final int endMs;

  final Color gridColor;
  final int gridLines;
  final double gridAlpha;
  final Map<String, Color> axisColors;
  final double axisStrokeWidth;
  final double axisGlowWidth;
  final double axisGlowAlpha;

  ChartPainter({
    required this.data,
    required this.startMs,
    required this.endMs,
    this.gridColor = AppColors.twoHundred,
    this.gridLines = 5,
    this.gridAlpha = 0.2,
    this.axisColors = const {
      'x': AppColors.blue,
      'y': AppColors.primary,
      'z': AppColors.secondary,
    },
    this.axisStrokeWidth = 2.4,
    this.axisGlowWidth = 6.0,
    this.axisGlowAlpha = 0.12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.resTs.isEmpty || endMs <= startMs) return;

    final gridPaint = Paint()
      ..color = gridColor.withAlpha((gridAlpha * 255).round())
      ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final resTs = data.resTs;
    final minV = data.minV;
    final maxV = data.maxV;
    final rx = data.rx;
    final ry = data.ry;
    final rz = data.rz;

    double tx(int t) => ((t - startMs) / (endMs - startMs)).clamp(0.0, 1.0) * size.width;
    double ty(double v) => size.height - ((v - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;

    Path buildSmoothPath(List<double> vals) {
      final path = Path();
      if (vals.isEmpty || resTs.isEmpty) return path;
      path.moveTo(tx(resTs.first), ty(vals.first));
      for (int i = 1; i < vals.length; i++) {
        final x1 = tx(resTs[i - 1]);
        final y1 = ty(vals[i - 1]);
        final x2 = tx(resTs[i]);
        final y2 = ty(vals[i]);
        final mx = (x1 + x2) / 2;
        final my = (y1 + y2) / 2;
        path.quadraticBezierTo(x1, y1, mx, my);
      }
      path.lineTo(tx(resTs.last), ty(vals.last));
      return path;
    }

    void paintAxis(List<double> vals, Color color) {
      if (vals.isEmpty) return;
      final paint = Paint()
        ..color = color.withAlpha((0.9 * 255).round())
        ..strokeWidth = axisStrokeWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      final path = buildSmoothPath(vals);
      canvas.drawPath(path, paint);

      final glow = Paint()
        ..color = color.withAlpha((axisGlowAlpha * 255).round())
        ..strokeWidth = axisGlowWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(path, glow);
    }

    paintAxis(rx, axisColors['x']!);
    paintAxis(ry, axisColors['y']!);
    paintAxis(rz, axisColors['z']!);
  }

  @override
  bool shouldRepaint(covariant ChartPainter old) {
    return old.data.resTs.length != data.resTs.length || old.startMs != startMs || old.endMs != endMs;
  }
}
