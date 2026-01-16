import 'package:flutter/material.dart';

class HomeRecordingRightBar extends StatelessWidget {
  const HomeRecordingRightBar({
    super.key,
    required this.onSettings,
    required this.onWaveSound,
    required this.onShutter,
    required this.onFlipCamera,
    required this.onBluetooth,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    this.isRecording = false,
  });

  final VoidCallback onSettings;
  final VoidCallback onWaveSound;
  final VoidCallback onShutter;
  final VoidCallback onFlipCamera;
  final VoidCallback onBluetooth;

  final EdgeInsets padding;

  // New flag to control icon swapping when recording
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    // White-ish side area like the screenshot.
    return Container(
      width: 150,
      color: Colors.white,
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 10),

          Btn(
            asset: 'assets/buttons/settings_button.png',
            size: 70,
            onTap: onSettings,
            semanticLabel: 'Settings',
          ),

          SizedBox(height: 140),

          Column(
            children: [
              Btn(
                asset: 'assets/buttons/wave-sound.png',
                size: 52,
                onTap: onWaveSound,
                semanticLabel: 'Wave sound',
              ),
              Btn(
                asset: isRecording
                    ? 'assets/buttons/shutter_on.png'
                    : 'assets/buttons/shutter.png',
                size: 76,
                onTap: onShutter,
                semanticLabel: isRecording ? 'Stop recording' : 'Record',
              ),
              Btn(
                asset: isRecording
                    ? 'assets/buttons/pause_flase.png'
                    : 'assets/buttons/flip_camera.png',
                size: 52,
                onTap: onFlipCamera,
                semanticLabel: isRecording ? 'Pause' : 'Flip camera',
              ),
            ],
          ),

          SizedBox(height: 140),

          Btn(
            asset: 'assets/buttons/bluetooth.png',
            size: 70,
            onTap: onBluetooth,
            semanticLabel: 'Bluetooth',
          ),
        ],
      ),
    );
  }
}

class Btn extends StatelessWidget {
  const Btn({
    required this.asset,
    required this.onTap,
    required this.semanticLabel,
    required this.size,
  });

  final String asset;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
