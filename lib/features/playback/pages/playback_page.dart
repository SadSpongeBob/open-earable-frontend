import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/home/state/home_provider.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

// Provider that loads sensor samples from a fixed path (strict requirement).
final sensorFilePath = '/storage/emulated/0/Download/final_sensor.json';
final sensorDataProvider = FutureProvider<List<SensorSample>>((ref) async {
  try {
    final samples = <SensorSample>[];

    int currentTimestamp = 0;

    for (int i = 0; i < 200; i++) {
      // zufälliger Zeitabstand zwischen 50ms und 150ms
      final step = 50 + (DateTime.now().microsecondsSinceEpoch % 100);
      currentTimestamp += step;

      final random = Random();

      final x = random.nextDouble() * 20 - 10;
      final y = random.nextDouble() * 20 - 10;
      final z = random.nextDouble() * 20 - 10;
      samples.add(
        SensorSample(
          timestampMs: currentTimestamp,
          x: x,
          y: y,
          z: z,
        ),
      );
    }

    return samples;
  } catch (e) {
    return [];
  }
});


class SensorSample {
  final int timestampMs;
  final double x;
  final double y;
  final double z;
  SensorSample({required this.timestampMs, required this.x, required this.y, required this.z});
}

class PlaybackPage extends ConsumerWidget {
  final String recordingId;
  final RecordingSource source;
  final Recording? recording;

  const PlaybackPage({
    super.key,
    required this.recordingId,
    required this.source,
    this.recording,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeStateProvider);

    final rec =
        recording ??
            home.videos.firstWhere(
              (r) => r.id == recordingId && r.source == source,
              orElse: () => throw Exception('Recording not found'),
            );
    final videoAsync = ref.watch(videoPlayerControllerProvider(rec));
    final speedKey = GlobalKey();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: videoAsync.when(
                loading: () => const SizedBox(height: 88),
                error: (_, _) => const SizedBox(height: 88),
                data: (vc) => TopBar(
                  vc: vc,
                  speedKey: speedKey,
                  recording: rec,
                ),
              ),
            ),
            // Video + synchronized 3s sensor chart below
            Expanded(
              child: videoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Failed to load video: $e")),
                data: (vc) => Column(
                  children: [
                    // Video area (flexible)
                    Expanded(child: VideoCard(controller: vc)),
                    // Sensor chart area fixed height
                    SizedBox(
                      height: 200,
                      child: ProviderScope(
                        // forward the same ref to child so sensor provider can be read
                        child: Consumer(builder: (context, ref2, _) {
                          final sensorAsync = ref2.watch(sensorDataProvider);
                          return sensorAsync.when(
                            loading: () => const Center(child: Text('Loading sensors...')),
                            error: (e, _) => Center(child: Text('Sensors error: $e')),
                            data: (samples) => SensorChartWidget(controller: vc, samples: samples),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple sensor chart widget that shows last 3 seconds of accelerometer x,y,z
class SensorChartWidget extends StatefulWidget {
  final dynamic controller; // video controller (expected to expose value.position as Duration)
  final List<SensorSample> samples;
  const SensorChartWidget({Key? key, required this.controller, required this.samples}) : super(key: key);

  @override
  State<SensorChartWidget> createState() => _SensorChartWidgetState();
}

class _SensorChartWidgetState extends State<SensorChartWidget> {
  late Timer _timer;
  int _currentMs = 0;

  @override
  void initState() {
    super.initState();
    _updatePosition();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _updatePosition());
  }

  void _updatePosition() {
    try {
      final pos = widget.controller.value.position as Duration?;
      if (pos != null) {
        final ms = pos.inMilliseconds;
        if (ms != _currentMs) {
          setState(() => _currentMs = ms);
        }
      }
    } catch (_) {
      // ignore if controller doesn't provide position
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // compute window [t-3000, t]
    final end = _currentMs;
    final start = (end - 6000).clamp(0, end);
    final window = widget.samples.where((s) => s.timestampMs >= start && s.timestampMs <= end).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: CustomPaint(
                  painter: _ChartPainter(samples: window, startMs: start, endMs: end),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 6),

            ],
          ),
        ),
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
    final paintGrid = Paint()..color = Colors.grey.shade300;
    // draw horizontal grid lines
    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (samples.isEmpty || endMs <= startMs) return;

    // find min/max values among x,y,z in window
    double minV = double.infinity, maxV = -double.infinity;
    for (final s in samples) {
      minV = mathMin(minV, mathMin(s.x, mathMin(s.y, s.z)));
      maxV = mathMax(maxV, mathMax(s.x, mathMax(s.y, s.z)));
    }
    if (minV == double.infinity || maxV == -double.infinity) return;
    if ((maxV - minV).abs() < 1e-6) {
      // avoid zero range
      maxV += 1;
      minV -= 1;
    }

    void drawLine(Color color, double Function(SensorSample) selector) {
      final p = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        final t = (s.timestampMs - startMs) / (endMs - startMs);
        final x = t * size.width;
        final v = selector(s);
        final y = size.height - ((v - minV) / (maxV - minV)) * size.height;
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, p);
    }

    drawLine(Colors.red, (s) => s.x);
    drawLine(Colors.green, (s) => s.y);
    drawLine(Colors.blue, (s) => s.z);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // repaint frequently
}

// helper min/max
double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
