import 'package:flutter/material.dart';

/// A controller that manages the display of a popup using an [OverlayEntry].
///
/// This class provides a simple API to show, hide, and toggle a popup overlay
/// that is positioned externally (via the provided [positionedPopup] widget).
///
/// The popup is inserted into the nearest [Overlay] of the given [BuildContext]
/// and includes a transparent background that closes the popup when tapped.
class DevicesPopupController {
  /// The current overlay entry used to render the popup.
  ///
  /// When null, no popup is visible.
  OverlayEntry? _entry;

  /// Whether the popup is currently open and inserted into the overlay.
  bool get isOpen => _entry != null;

  /// Shows the popup overlay if it is not already open.
  ///
  /// The [context] is used to obtain the nearest [Overlay] to insert the popup.
  /// The [positionedPopup] should be a fully positioned widget (e.g. using
  /// [Positioned]) that defines where the popup appears on screen.
  ///
  /// Tapping outside the popup area will automatically call [hide].
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

  /// Hides the popup overlay if it is currently open.
  void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// Toggles the visibility of the popup overlay.
  ///
  /// If the popup is open, it will be hidden using [hide].
  /// Otherwise, it will be shown using [show] with the provided parameters.
  ///
  /// Requires the same [context] and [positionedPopup] as [show].
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
