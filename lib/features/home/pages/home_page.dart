import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/home/widgets/project_bar.dart';
import '../../../app/routing/routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Row(
        children: [
          const ProjectBar(folders: [],),

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

          HomeRecordingRightBar(
            onSettings: () => context.go(Routes.settings),
            onWaveSound: () {
              // TODO: open sensor data page
            },
            onShutter: () => context.go(Routes.recording),
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