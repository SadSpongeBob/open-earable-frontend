import 'package:flutter/material.dart';

class HomeRecordingRightBar extends StatelessWidget {
  const HomeRecordingRightBar({
    super.key,
    required this.onSettings,
    required this.onWaveSound,
    required this.onShutter,
    this.onFlipCamera,
    required this.onBluetooth,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    this.isRecording = false,
    this.isPaused = false,
    this.showFlipButton = true,
  })  : assert(!showFlipButton || onFlipCamera != null,
            'onFlipCamera must be provided when showFlipButton is true');

  final VoidCallback onSettings;
  final VoidCallback onWaveSound;
  final VoidCallback onShutter;
  final VoidCallback? onFlipCamera;
  final VoidCallback onBluetooth;

  final EdgeInsets padding;

  final bool isRecording;
  final bool isPaused;
  final bool showFlipButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.white,
      padding: padding,
      child: Column(
        children: [
          Btn(
            asset: 'assets/buttons/settings_button.png',
            size: 70,
            onTap: onSettings,
            semanticLabel: 'Settings',
          ),

          const Spacer(),
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
                semanticLabel:
                isRecording ? 'Stop recording' : 'Record',
              ),

              if (showFlipButton)
                Btn(
                  asset: isRecording
                      ? (isPaused
                          ? 'assets/buttons/pause_true.png'
                          : 'assets/buttons/pause_flase.png')
                      : 'assets/buttons/flip_camera.png',
                  size: 52,
                  onTap: onFlipCamera,
                  semanticLabel: isRecording
                      ? (isPaused ? 'Resume recording' : 'Pause recording')
                      : 'Flip camera',
                ),
            ],
          ),

          const Spacer(),
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
    super.key,
    required this.asset,
    required this.onTap,
    required this.semanticLabel,
    required this.size,
  });

  final String asset;
  final VoidCallback? onTap;
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
