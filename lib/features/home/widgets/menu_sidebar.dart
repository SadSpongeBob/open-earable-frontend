import 'package:flutter/material.dart';
import 'image_button.dart';

class MenuSidebar extends StatelessWidget {
  final GlobalKey bluetoothKey;
  final VoidCallback onSettingsPressed;
  final VoidCallback onRecordingPressed;
  final VoidCallback onBluetoothPressed;


  const MenuSidebar({
    super.key,
    required this.bluetoothKey,
    required this.onSettingsPressed,
    required this.onRecordingPressed,
    required this.onBluetoothPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2),
        boxShadow: const [
            BoxShadow(
              color: Color(0xFF8F8F8F),
              blurRadius: 30,
              offset: Offset(3, 0),
            )
          ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ImageButton(
              image: 'assets/images/settings.png',
              activeImage: 'assets/images/settings_active.png',
              onPressed: onSettingsPressed,
              width: 70,
              height: 70,
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: ImageButton(
              image: 'assets/images/recording.png',
              activeImage: 'assets/images/recording_active.png',
              onPressed: onRecordingPressed,
              width: 76,
              height: 76,
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: ImageButton(
              buttonKey: bluetoothKey,
              image: 'assets/images/bluetooth.png',
              activeImage: 'assets/images/bluetooth_active.png',
              onPressed: onBluetoothPressed,
              width: 70,
              height: 70,
            ),
          ),
        ],
      ),
    );
  }
}