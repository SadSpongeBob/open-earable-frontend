import 'package:flutter/material.dart';
import 'package:openearable/features/recordings/pages/recording_page.dart';
import 'package:openearable/features/settings/pages/settings_page.dart';
import 'package:openearable/app/widgets/menu_sidebar.dart';
import 'package:openearable/features/home/pages/sensor_page.dart';
import 'package:openearable/app/utils/helpers.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecordingPage(),
                  ),
                );
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