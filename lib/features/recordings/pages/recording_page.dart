import 'package:flutter/material.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';
import 'package:openearable/app/widgets/menu_sidebar.dart';
import 'package:openearable/features/home/pages/sensor_page.dart';
import 'package:openearable/app/utils/helpers.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  bool isSensorRecording = false;
  final GlobalKey _btButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            /// Temporary Box to have a correct location of the MenuSidebar
            Expanded(
              child: Row(),
            ),

            MenuSidebar(
              bluetoothKey: _btButtonKey,
              onSettingsPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
              onSensorPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SensorPage(
                      source: SensorPageSource.home,
                      onBluetoothPressed: () {
                        showDevicesPopup(
                          context: context,
                          isSensorPage: true,
                        );
                      },
                    ),
                  ),
                );
              },
              onRecordingPressed: () {
                // Start recording
              },
              showFlipButton: true,
              onFlipPressed: () {
                // Flip the camera
              },
              onBluetoothPressed: () {
                showDevicesPopup(
                  context: context,
                  isSensorPage: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
