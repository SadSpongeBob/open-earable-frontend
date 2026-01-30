import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/home/state/wearables_provider.dart';
import 'image_button.dart';

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
    return Consumer<WearablesProvider>(
      builder: (context, provider, _) {
        final isConnected = provider.wearables.isNotEmpty;

        return ImageButton(
          buttonKey: buttonKey,
          image: 'assets/buttons/bluetooth.png',
          activeImage: 'assets/buttons/bluetooth_connected.png',
          isActive: isConnected,
          width: size,
          height: size,
          onPressed: onPressed,
        );
      },
    );
  }
}
