import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:path_provider/path_provider.dart';

import '../controllers/playback_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/video_card.dart';

/// Provider that loads sensor samples from app directory
final sensorDataProvider = FutureProvider<List<SensorSample>>((ref) async {
  debugPrint("\n==============================");
  debugPrint("🔥 SENSOR PROVIDER STARTED");
  debugPrint("==============================");

  try {
    // 1. Directory
    final dir = await getApplicationDocumentsDirectory();
    debugPrint("📁 App Directory Path = ${dir.path}");

    // 2. File Path
    final filePath = "${dir.path}/sensor.json";
    final file = File(filePath);

    debugPrint("📄 Looking for file: $filePath");

    // 3. File Exists?
    if (!await file.exists()) {
      debugPrint("❌ ERROR: sensor.json NOT FOUND!");
      return [];
    }

    debugPrint("✅ File FOUND!");

    // 4. Read file content
    final jsonString = await file.readAsString();
    debugPrint("✅ File Read Success!");
    debugPrint("📦 File length = ${jsonString.length} characters");

    debugPrint("📌 File Preview:");
    debugPrint(jsonString.substring(0, min(300, jsonString.length)));

    // 5. Decode JSON
    final decoded = jsonDecode(jsonString);
    debugPrint("✅ JSON Decode Success!");
    debugPrint("Top-level keys = ${decoded.keys}");

    // 6. Check samples
    if (!decoded.containsKey("samples")) {
      debugPrint("❌ ERROR: JSON has NO 'samples' key!");
      return [];
    }

    final rawSamples = decoded["samples"];
    debugPrint("✅ samples key found!");
    debugPrint("Raw samples type = ${rawSamples.runtimeType}");
    debugPrint("Raw samples count = ${rawSamples.length}");

    if (rawSamples.isEmpty) {
      debugPrint("❌ ERROR: samples list is EMPTY!");
      return [];
    }

    // 7. Extract all accelerometer samples
    final accelSamples = <SensorSample>[];

    for (int i = 0; i < rawSamples.length; i++) {
      final s = rawSamples[i];
      if (!s.containsKey("timestampMs") || !s.containsKey("values")) continue;

      final timestamp = s["timestampMs"];
      final values = s["values"];

      if (!values.containsKey("Accelerometer")) continue;

      final accel = values["Accelerometer"];
      if (accel is! List || accel.length < 3) continue;

      accelSamples.add(
        SensorSample(
          timestampMs: timestamp,
          x: accel[0].toDouble(),
          y: accel[1].toDouble(),
          z: accel[2].toDouble(),
        ),
      );
    }

    debugPrint("✅ TOTAL ACCEL SAMPLES LOADED = ${accelSamples.length}");
    if (accelSamples.isEmpty) return [];

    // 8. Normalize timestamps (start at 0ms)
    final base = accelSamples.first.timestampMs;
    final normalized = accelSamples
        .map((s) => SensorSample(
      timestampMs: s.timestampMs - base,
      x: s.x,
      y: s.y,
      z: s.z,
    ))
        .toList();

    debugPrint("✅ Normalization done!");
    debugPrint("First normalized timestamp = ${normalized.first.timestampMs}");

    return normalized;
  } catch (e, st) {
    debugPrint("❌ EXCEPTION: $e");
    debugPrint("STACKTRACE:\n$st");
    return [];
  }
});

class SensorSample {
  final int timestampMs;
  final double x;
  final double y;
  final double z;
  SensorSample({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.z,
  });
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

    final rec = recording ??
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
                error: (_, __) => const SizedBox(height: 88),
                data: (vc) => TopBar(vc: vc, speedKey: speedKey, recording: rec),
              ),
            ),
            Expanded(
              child: videoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(child: Text("Failed to load video: $e")),
                data: (vc) => Column(
                  children: [
                    Expanded(child: VideoCard(controller: vc)),
                    SizedBox(
                      height: 200,
                      child: ProviderScope(
                        child: Consumer(builder: (context, ref2, _) {
                          final sensorAsync = ref2.watch(sensorDataProvider);
                          return sensorAsync.when(
                            loading: () =>
                            const Center(child: Text('Loading sensors...')),
                            error: (e, _) =>
                                Center(child: Text('Sensors error: $e')),
                            data: (samples) =>
                                SensorChartWidget(controller: vc, samples: samples),
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
  late Timer _timer;
  int _currentMs = 0;

  @override
  void initState() {
    super.initState();
    _updatePosition();
    _timer =
        Timer.periodic(const Duration(milliseconds: 200), (_) => _updatePosition());
  }

  void _updatePosition() {
    try {
      final pos = widget.controller.value.position as Duration?;
      if (pos != null) {
        final ms = pos.inMilliseconds;
        if (ms != _currentMs) setState(() => _currentMs = ms);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = _currentMs;
    final start = (end - 3000).clamp(0, end);

    // Filter Samples für Fenster
    final window = widget.samples
        .where((s) => s.timestampMs >= start && s.timestampMs <= end)
        .toList();

    debugPrint("Chart window: start=$start, end=$end, samples=${window.length}");

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: _ChartPainter(samples: window, startMs: start, endMs: end),
            child: Container(),
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
    debugPrint("Chart got ${samples.length} samples");

    final paintGrid = Paint()..color = Colors.grey.shade300;
    // horizontale Linien
    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (samples.isEmpty || endMs <= startMs) return;

    double minV = double.infinity, maxV = -double.infinity;
    for (final s in samples) {
      minV = mathMin(minV, mathMin(s.x, mathMin(s.y, s.z)));
      maxV = mathMax(maxV, mathMax(s.x, mathMax(s.y, s.z)));
    }

    // Vermeide zero range
    if ((maxV - minV).abs() < 1e-6) {
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
        final y = size.height - ((selector(s) - minV) / (maxV - minV)) * size.height;

        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
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
