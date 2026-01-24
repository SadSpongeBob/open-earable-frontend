import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/home/controllers/wearables_provider.dart';
import 'package:provider/provider.dart';

import 'package:openearable/app/utils/logger.dart';
import 'package:openearable/api/models/device/wearable_connector.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// Page for connecting to devices
///
/// All BLE devices are listed and tapping on it will connect to the device.
/// Connected Wearables are added to the [WearablesProvider].
class DevicesPopup extends StatefulWidget {
  const DevicesPopup({super.key});

  @override
  State<DevicesPopup> createState() => _DevicesPopup();
}

class _DevicesPopup extends State<DevicesPopup> {
  final WearableManager _wearableManager = WearableManager();
  StreamSubscription? _scanSubscription;

  List<DiscoveredDevice> discoveredDevices = [];
  Map<String, bool> connectingDevices = {};
  final Set<String> failedDevices = {};
  static final Set<String> connectedDevices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 550,
      width: 300,
      child: Column(
        children: [
          const SizedBox(height: 30),

          Text(
            "Devices",
            style: AppTextStyles.headerMedium,
          ),

          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = discoveredDevices[index];

                bool isConnecting = connectingDevices[device.id] ?? false;
                bool isConnected = connectedDevices.contains(device.id);
                bool isConnectionFailed = failedDevices.contains(device.id);

                String? statusText;

                if (isConnecting) {
                  statusText = "Connecting...";
                } else if (isConnected) {
                  statusText = "Connected";
                } else if (isConnectionFailed) {
                  statusText = "Connection failed";
                }

                return InkWell(
                  onTap: isConnected || isConnecting ? null : () => _connectToDevice(device, context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/images/device.png',
                              width: 65,
                              height: 65,
                              fit: BoxFit.contain,
                            ),

                            if (isConnecting)
                              Positioned(
                                right: -15,
                                top: -15,
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        
                            if (!isConnecting && isConnected)
                              Positioned(
                                right: -15,
                                top: -15,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                            if (isConnectionFailed)
                              Positioned(
                                right: -15,
                                top: -15,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          device.name,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text,
                        ),

                        const SizedBox(height: 4),

                        if (statusText != null)
                          Text(
                            statusText,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.footnoteDevices,
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startScanning() async {
  try {
    await _wearableManager.startScan();
    _scanSubscription?.cancel();
    _scanSubscription = _wearableManager.scanStream.listen((incomingDevice) {
      // bool isTargetDevice = incomingDevice.name.toLowerCase().contains("esense") || 
      //                      incomingDevice.name.toLowerCase().contains("openearable");
      if (incomingDevice.name.isNotEmpty &&
          !discoveredDevices.any((d) => d.id == incomingDevice.id)) {
        setState(() {
          discoveredDevices.add(incomingDevice);
        });
      }
    });
  } catch (e) {
    logger.e('Failed to start scan: $e');
  }
}

  Future<void> _connectToDevice(
  DiscoveredDevice device,
  BuildContext context,
) async {
  setState(() {
    connectingDevices[device.id] = true;
  });

  try {
    final connector = context.read<WearableConnector>();
    final wearablesProvider = context.read<WearablesProvider>();

    final wearable = await connector.connect(device);

    wearablesProvider.addWearable(wearable);

    setState(() {
      failedDevices.remove(device.id);
      connectedDevices.add(device.id);
    });
  } catch (e) {
    final message = _wearableManager.deviceErrorMessage(e, device.name);
    logger.e('Failed to connect to device: ${device.name}, error: $message');

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Connection Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() {
      failedDevices.add(device.id);
      connectedDevices.remove(device.id);
    });
  } finally {
    setState(() {
      connectingDevices.remove(device.id);
    });
  }
}

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
