import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/home/state/wearables_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WearablesProvider>().startScanning();
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
            style: GlobalTextStyles.headerMedium,
          ),

          const SizedBox(height: 30),

          Expanded(
            child: FutureBuilder<List<String>>(
              future: _checkSystemStatus(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final errors = snapshot.data ?? [];

                if (errors.isNotEmpty) {
                  // Bluetooth or Location is off
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: errors.map((error) {
                        IconData icon;
                        if (error.contains("Bluetooth")) {
                          icon = Icons.bluetooth_disabled;
                        } else if (error.contains("Location")) {
                          icon = Icons.location_off;
                        } else {
                          icon = Icons.error;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Color(0xFF1F1F1F), size: 26),
                              const SizedBox(width: 8),
                              Text(
                                error,
                                style: GlobalTextStyles.subHeader,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }

                // Bluetooth and Location are ON, show the devices list
                final wearableProvider = context.watch<WearablesProvider>();

                final discovered = wearableProvider.discoveredDevices;
                final connecting = wearableProvider.connectingDevices;
                final failed = wearableProvider.failedDevices;
                final connected = wearableProvider.wearables.map((w) => w.deviceId).toSet();

                return ListView.builder(
                  itemCount: discovered.length,
                  itemBuilder: (context, index) {
                    final device = discovered[index];

                    bool isConnecting = connecting[device.id] ?? false;
                    bool isConnected = connected.contains(device.id);
                    bool isConnectionFailed = failed.contains(device.id);

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
                                  _statusCircle(color: Colors.green, isConnecting: isConnecting),
                        
                                if (!isConnecting && isConnected)
                                  _statusCircle(color: Colors.green, isConnecting: isConnecting),

                                if (isConnectionFailed)
                                  _statusCircle(color: Colors.redAccent, isConnecting: isConnecting),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              device.name,
                              textAlign: TextAlign.center,
                              style: GlobalTextStyles.text,
                            ),

                            const SizedBox(height: 4),

                            if (statusText != null)
                              Text(
                                statusText,
                                textAlign: TextAlign.center,
                                style: GlobalTextStyles.footnote,
                                selectionColor: Color(0xFF6E6E6E),
                              ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCircle({required Color color, required bool isConnecting}) {
    return Positioned(
      right: -15,
      top: -15,
      child: isConnecting
      ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
      : Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
    );
  }

  Future<void> _connectToDevice(
    DiscoveredDevice device,
    BuildContext context,
  ) async {
    final provider = context.read<WearablesProvider>();
    provider.setConnecting(device.id, true);

    try {
      final connector = context.read<WearableConnector>();
      final wearable = await connector.connect(device);

      provider.addWearable(wearable);
      provider.setFailed(device.id, false);
    } catch (e) {
      provider.setFailed(device.id, true);
    } finally {
      provider.setConnecting(device.id, false);
    }
  }

  Future<List<String>> _checkSystemStatus(BuildContext context) async {
    final provider = context.read<WearablesProvider>();
    List<String> errors = [];

    if (!await provider.isBluetoothOn) {
      errors.add("Bluetooth is off");
    }

    if (!await provider.isLocationOn) {
      errors.add("Location is off");
    }

    return errors;
  }
}
