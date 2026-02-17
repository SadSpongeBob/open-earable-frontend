import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/sensor_chart_controller.dart';
import '../../../api/services/recording/sensor_repository.dart';
import '../controllers/chart_data.dart';
import 'chart_painter.dart';

class SensorChartWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final List<SensorSample> samples;

  const SensorChartWidget({
    super.key,
    required this.controller,
    required this.samples,
  });

  @override
  State<SensorChartWidget> createState() => _SensorChartWidgetState();
}

class _SensorChartWidgetState extends State<SensorChartWidget> {
  late final VoidCallback _listener;
  late SensorChartController _logic;
  int _currentMs = 0;

  @override
  void initState() {
    super.initState();
    _logic = SensorChartController(samples: widget.samples);
    _listener = () {
      final pos = widget.controller.value.position;
      final ms = pos.inMilliseconds;
      if (ms != _currentMs) setState(() => _currentMs = ms);
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SensorChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.samples, widget.samples)) {
      _logic = SensorChartController(samples: widget.samples);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = _currentMs;
    final start = (end - _logic.windowMs) < 0 ? 0 : (end - _logic.windowMs);
    final windowSamples = _logic.windowFor(end);
    final chartData = ChartData.fromSamples(windowSamples, start, end);
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).round()),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                painter: ChartPainter(
                  data: chartData,
                  startMs: start,
                  endMs: end,
                ),
                child: Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
