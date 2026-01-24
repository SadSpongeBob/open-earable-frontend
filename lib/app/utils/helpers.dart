import 'package:flutter/material.dart';
import 'package:openearable/features/home/widgets/devices_popup.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

OverlayEntry? devicesPopupEntry;

void showDevicesPopup({
  required BuildContext context,
  required Offset offset,
}) {
  // Prevent multiple popups
  if (devicesPopupEntry != null) return;

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
          right: offset.dx,
          bottom: offset.dy,
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

  Overlay.of(context).insert(devicesPopupEntry!);
}
