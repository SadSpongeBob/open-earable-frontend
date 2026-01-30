import 'package:flutter/material.dart';
import 'package:openearable/features/home/widgets/devices_popup.dart';

OverlayEntry? devicesPopupEntry;

void showDevicesPopup({
  required BuildContext context,
  required bool isSensorPage,
}) {
  // Prevent multiple popups
  if (devicesPopupEntry != null) return;

  double? top, left, bottom, right;
  if (isSensorPage) {
    // Left side, fixed top offset
    top = 30;
    left = 295;
    bottom = null;
    right = null;
  } else {
    // Right side, fixed bottom offset
    top = null;
    left = null;
    bottom = 30;
    right = 165;
  }

  devicesPopupEntry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        GestureDetector(
          onTap: () {
            devicesPopupEntry?.remove();
            devicesPopupEntry = null;
          },
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          top: top,
          left: left,
          bottom: bottom,
          right: right,
          child: Material(
            elevation: 20,
            borderRadius: BorderRadius.circular(36),
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 550,
              width: 300,
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

  Overlay.of(context).insert(devicesPopupEntry!);
}