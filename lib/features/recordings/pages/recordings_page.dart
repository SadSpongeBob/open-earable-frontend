import 'package:flutter/material.dart';
import 'package:openearable/features/home/pages/home_page.dart';

import '../widgets/left_bar.dart';
import '../widgets/right_bar.dart';
import '../widgets/recording_camera_area.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  bool _isRecording = false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }
  void _flipCamera() {
    // TODO: Integrate with camera controller to switch cameras
  }
  void _onRecordingComplete() {
    // TODO: Handle post-recording actions such as saving or uploading the video
  }

  void _ontoggleSensorData() {
    // TODO: Implement sensor data toggling
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // LEFT BAR
            RecordingLeftBar(
              onBackToProjects: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),

            // CAMERA AREA
            Expanded(
              child: RecordingCameraArea(
                isRecording: _isRecording,
                onShutter: _toggleRecording,
                onFlipCamera: _flipCamera,
              ),
            ),

            // RIGHT BAR
            HomeRecordingRightBar(
              onSettings: () {
                // TODO
              },
              onWaveSound: () {
                // TODO
              },
              onShutter: _toggleRecording,
              onFlipCamera: _flipCamera,
              onBluetooth: () {
                // TODO
              },
            ),
          ],
        ),
      ),
    );
  }
}
