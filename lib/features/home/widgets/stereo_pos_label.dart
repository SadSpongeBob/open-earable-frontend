import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;

import 'package:openearable/app/utils/logger.dart';

class StereoPosLabel extends StatelessWidget {
  final StereoDevice device;

  const StereoPosLabel({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: device.position,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          logger.e("Error fetching device position: ${snapshot.error}");
          return Text("Error: ${snapshot.error}");
        }
        if (!snapshot.hasData) {
          return Text("N/A");
        }
        if (snapshot.data == null) {
          return Text("N/A");
        }
        switch (snapshot.data) {
          case DevicePosition.left:
            return Text("Left");
          case DevicePosition.right:
            return Text("Right");
          default:
            return Text("Unknown");
        }
      },
    );
  }
}
