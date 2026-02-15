import 'package:flutter/material.dart';

class DevicesPopupController {
  OverlayEntry? _entry;

  bool get isOpen => _entry != null;

  void show({
    required BuildContext context,
    required Widget positionedPopup,
  }) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: hide,
            child: Container(color: Colors.transparent),
          ),
          positionedPopup,
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  void toggle({
    required BuildContext context,
    required Widget positionedPopup,
  }) {
    if (isOpen) {
      hide();
    } else {
      show(
        context: context,
        positionedPopup: positionedPopup,
      );
    }
  }
}
