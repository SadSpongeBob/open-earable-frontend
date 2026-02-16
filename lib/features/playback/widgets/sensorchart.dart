import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/sensor_repository.dart';


class SensorChartWidget extends StatefulWidget {
  final dynamic controller;
  final List<SensorSample> samples;

  const SensorChartWidget({
    Key? key,
    required this.controller,
    required this.samples,
  }) : super(key: key);

  @override
  State<SensorChartWidget> createState() => _SensorChartWidgetState();
}

class _SensorChartWidgetState extends State<SensorChartWidget> {
  late final VoidCallback _listener;
  int _currentMs = 0;

  @override
  void initState() {
    super.initState();

    // Listener direkt auf Video-Controller
    _listener = () {
      final pos = widget.controller.value.position;
      if (pos != null) {
        final ms = pos.inMilliseconds;
        if (ms != _currentMs) {
          setState(() => _currentMs = ms);
        }
      }
    };

    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = _currentMs;
    final start = (end - 7000).clamp(0, end); // 3 Sekunden Fenster

    // Sensorwerte nur für den aktuellen Fensterbereich
    final window = widget.samples
        .where((s) => s.timestampMs >= start && s.timestampMs <= end)
        .toList();

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          CustomPaint(
            painter: _ChartPainter(samples: window, startMs: start, endMs: end),
            child: Container(),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SensorSample> samples;
  final int startMs;
  final int endMs;

  _ChartPainter({required this.samples, required this.startMs, required this.endMs});

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund Grid
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (samples.isEmpty || endMs <= startMs) return;

    // Min/Max berechnen
    double minV = double.infinity, maxV = -double.infinity;
    for (final s in samples) {
      minV = mathMin(minV, mathMin(s.x, mathMin(s.y, s.z)));
      maxV = mathMax(maxV, mathMax(s.x, mathMax(s.y, s.z)));
    }

    // Padding oben/unten
    double paddingFactor = 0.1;
    double paddedMinV = minV - (maxV - minV) * paddingFactor;
    double paddedMaxV = maxV + (maxV - minV) * paddingFactor;

    // Gerade Linien zeichnen (nicht curved)
    void drawLine(Color color, double Function(SensorSample) selector) {
      final p = Paint()
        ..color = color.withOpacity(0.9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final path = Path();

      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        final t = (s.timestampMs - startMs) / (endMs - startMs);
        final x = t * size.width;
        final y = size.height - ((selector(s) - paddedMinV) / (paddedMaxV - paddedMinV)) * size.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y); // gerade Linie zwischen Punkten
        }
      }

      canvas.drawPath(path, p);
    }

    drawLine(Colors.red, (s) => s.x);
    drawLine(Colors.green, (s) => s.y);
    drawLine(Colors.blue, (s) => s.z);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.samples != samples || old.startMs != startMs || old.endMs != endMs;
}


double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
