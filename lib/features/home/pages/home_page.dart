import 'package:flutter/material.dart';
import 'package:openearable/features/home/pages/recording_page.dart';
import 'package:openearable/features/home/pages/settings_page.dart';
import 'package:openearable/features/home/widgets/devices_popup.dart';
import 'package:openearable/features/home/widgets/menu_sidebar.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final GlobalKey _btButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onRecordingPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecordingPage(),
                ),
              );
            },
            onBluetoothPressed: () {
              _showBluetoothPopup(context, _btButtonKey);
            },
          ),
        ],
      ),
    );
  }
}

void _showBluetoothPopup(BuildContext context, GlobalKey buttonKey) {
  final RenderBox? renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        GestureDetector(
          onTap: () => overlayEntry.remove(),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          right: 165,
          bottom: 30,
          child: Material(
            elevation: 20,
            borderRadius: BorderRadius.circular(36),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const DevicesPopup(),
            ),
          ),
        ),
      ],
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}