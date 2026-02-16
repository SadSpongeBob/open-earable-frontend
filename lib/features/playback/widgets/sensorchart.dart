import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controllers/sensor_repository.dart';

class SensorChartWidget extends StatefulWidget {
  final dynamic controller; // VideoController
  final List<SensorSample> samples;
  final bool allowToggleAxes;

  const SensorChartWidget({
    Key? key,
    required this.controller,
    required this.samples,
    this.allowToggleAxes = false,
  }) : super(key: key);

  @override
  State<SensorChartWidget> createState() => _SensorChartWidgetState();
}

class _SensorChartWidgetState extends State<SensorChartWidget> {
  late final VoidCallback _listener;
  int _currentMs = 0;
  late Map<String, bool> _axisEnabled;

  @override
  void initState() {
    super.initState();

    // Standardmäßig alle Achsen aktiv
    _axisEnabled = {
      "X": true,
      "Y": true,
      "Z": true,
    };

    _listener = () {
      final pos = widget.controller.value.position;
      if (pos != null) {
        final ms = pos.inMilliseconds;
        if (ms != _currentMs) setState(() => _currentMs = ms);
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
   // Offset, um Video vor Sensoren zu halten
    final end = _currentMs;
    final start = (end - 7000).clamp(0, end); // 7 Sekunden Fenster

    debugPrint("⏱ Video-Position: $_currentMs ms, Fenster: $start - $end");
    debugPrint("🔹 Anzahl Samples insgesamt: ${widget.samples.length}");
    debugPrint("🔹 Erste Sample: ${widget.samples.isNotEmpty ? widget.samples.first : 'none'}");
    debugPrint("🔹 Letzte Sample: ${widget.samples.isNotEmpty ? widget.samples.last : 'none'}");

    final window = widget.samples
        .where((s) => s.timestampMs >= start && s.timestampMs <= end)
        .toList();

    debugPrint("📊 Anzahl Samples im Fenster: ${window.length}");
    if (window.isNotEmpty) {
      debugPrint("📍 Fenster erster Sample: ${window.first}");
      debugPrint("📍 Fenster letzter Sample: ${window.last}");
    }

    return Column(
      children: [
        if (widget.allowToggleAxes)
          Wrap(
            spacing: 8,
            children: _axisEnabled.keys.map((axis) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _axisEnabled[axis],
                    onChanged: (v) {
                      setState(() => _axisEnabled[axis] = v ?? false);
                    },
                    activeColor: _axisColor(axis),
                  ),
                  Text(axis),
                ],
              );
            }).toList(),
          ),
        Expanded(
          child: Stack(
            children: [
              // Hintergrund Grid
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              CustomPaint(
                painter: _ChartPainter(
                  samples: window,
                  startMs: start,
                  endMs: end,
                  axisEnabled: _axisEnabled,
                ),
                child: Container(),
              ),
              // Time axis bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Text(
                  "Time: ${(_currentMs / 1000).toStringAsFixed(2)} s",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _axisColor(String axis) {
    switch (axis.toLowerCase()) {
      case 'x':
        return Colors.red;
      case 'y':
        return Colors.green;
      case 'z':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<SensorSample> samples;
  final int startMs;
  final int endMs;
  final Map<String, bool> axisEnabled;

  _ChartPainter({
    required this.samples,
    required this.startMs,
    required this.endMs,
    required this.axisEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (samples.isEmpty || endMs <= startMs) return;

    // Min/Max für sichtbaren Bereich
    double minV = double.infinity, maxV = -double.infinity;
    for (final s in samples) {
      if (axisEnabled["X"] == true) {
        minV = mathMin(minV, s.x);
        maxV = mathMax(maxV, s.x);
      }
      if (axisEnabled["Y"] == true) {
        minV = mathMin(minV, s.y);
        maxV = mathMax(maxV, s.y);
      }
      if (axisEnabled["Z"] == true) {
        minV = mathMin(minV, s.z);
        maxV = mathMax(maxV, s.z);
      }
    }

    if ((maxV - minV).abs() < 1e-6) {
      maxV += 1;
      minV -= 1;
    }

    double padding = 0.1;
    double paddedMinV = minV - (maxV - minV) * padding;
    double paddedMaxV = maxV + (maxV - minV) * padding;

    // Zeichne Linien
    void drawLine(double Function(SensorSample) selector, Color color) {
      final p = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        final t = (s.timestampMs - startMs) / (endMs - startMs);
        final x = t * size.width;
        final y = size.height - ((selector(s) - paddedMinV) / (paddedMaxV - paddedMinV)) * size.height;

        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }

      canvas.drawPath(path, p);
    }

    if (axisEnabled["X"] == true) drawLine((s) => s.x, Colors.red);
    if (axisEnabled["Y"] == true) drawLine((s) => s.y, Colors.green);
    if (axisEnabled["Z"] == true) drawLine((s) => s.z, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.samples != samples ||
          old.startMs != startMs ||
          old.endMs != endMs ||
          old.axisEnabled != axisEnabled;
}

double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
