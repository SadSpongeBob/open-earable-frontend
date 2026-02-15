import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:openearable/features/sensors/widgets/sensor_chart.dart';
//import 'package:openearable/features/sensors/state/sensor_state.dart';
//import 'package:openearable/features/home/state/wearables_state.dart';
//import 'package:openearable/app/theme/text_styles.dart';

class VideoSensorOverlay extends ConsumerWidget {
  const VideoSensorOverlay({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  // IGNORE ALL LOGIC FOR ONE SECOND TO SEE IF THE UI WORKS
  return Align(
    alignment: Alignment.center,
    child: Container(
      width: 200,
      height: 100,
      color: Colors.purple, // If you don't see a purple box, the Stack is broken
      child: const Text("IF YOU SEE THIS, THE STACK IS OK", 
        style: TextStyle(color: Colors.white)),
    ),
  );
}
}