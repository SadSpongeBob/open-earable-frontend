import 'package:flutter/material.dart';

class RecordingCameraArea extends StatelessWidget {
  const RecordingCameraArea({
    super.key,
    required this.isRecording,
    required this.onShutter,
    required this.onFlipCamera,
  });

  final bool isRecording;
  final VoidCallback onShutter;
  final VoidCallback onFlipCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // TODO: Integrate camera preview here danke mahdi :)
        ],
      ),
    );
  }
}

