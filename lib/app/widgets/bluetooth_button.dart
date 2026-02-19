import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'image_button.dart';

/// A Bluetooth connection button that reflects the current wearable
/// connection state.
///
/// The button automatically switches between active and inactive
/// visuals based on whether any wearables are connected via
/// [wearablesProvider]. It uses an [ImageButton] internally to
/// display the appropriate Bluetooth icon.
/// 
/// Parameters:
/// - [onPressed]: Callback invoked when the button is pressed.
/// - [buttonKey]: Optional key used to uniquely identify and access the button widget.
/// - [size]: The width and height of the button in logical pixels. Defaults to 70.
class BluetoothButton extends StatelessWidget {
  final VoidCallback onPressed;
  final GlobalKey? buttonKey;
  final double size;

  const BluetoothButton({
    super.key,
    required this.onPressed,
    this.buttonKey,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final provider = ref.watch(wearablesProvider);
        final isConnected = provider.wearables.isNotEmpty;

        return ImageButton(
          buttonKey: buttonKey,
          image: 'assets/buttons/bluetooth.png',
          activeImage: 'assets/buttons/bluetooth_connected.png',
          isActive: isConnected,
          width: size,
          height: size,
          onPressed: onPressed,
          semanticLabel: 'Connect Bluetooth device',
        );
      },
    );
  }
}
