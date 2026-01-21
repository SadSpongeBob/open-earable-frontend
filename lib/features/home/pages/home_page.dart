import 'package:flutter/material.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/recordings/pages/recordings_page.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';
import 'package:openearable/features/home/widgets/project_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToRecording(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordingPage()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          // ProjectBar: white empty bar with fixed width 500 on the far left
          const ProjectBar(folders: [],),

          // Main content area: show background image only in this central area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Right-side recording controls
          HomeRecordingRightBar(
            onSettings: () => _navigateToSettings(context),
            onWaveSound: () {
              // TODO: open sensor data page
            },
            onShutter: () => _navigateToRecording(context),
            onBluetooth: () {
              // TODO: open bleutooth popup
            },
            padding: const EdgeInsets.symmetric(vertical: 24),
            isRecording: false,
            isPaused: false,
            showFlipButton: false,
          ),
        ],
      ),
    );
  }
}