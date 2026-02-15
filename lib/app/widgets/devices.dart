import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/home/state/wearables_provider.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// Page for connecting to devices
///
/// All BLE devices are listed and tapping on it will connect to the device.
/// Connected Wearables are added to the [WearablesProvider].
class Devices extends ConsumerStatefulWidget {
  const Devices({super.key});

  @override
  ConsumerState<Devices> createState() => _Devices();
}

class _Devices extends ConsumerState<Devices> {
  late final Future<List<SystemIssue>> _systemStatusFuture;

  @override
  void initState() {
    super.initState();
    _systemStatusFuture = _checkSystemStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wearablesProvider).startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<SystemIssue>>(
        future: _systemStatusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final issues = snapshot.data ?? [];

          if (issues.isNotEmpty) {
          // Bluetooth or Location is off
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: issues.map((issue) {
                  final icon = switch (issue) {
                    SystemIssue.bluetoothOff => Icons.bluetooth_disabled,
                    SystemIssue.locationOff => Icons.location_off,
                  };

                  final message = switch (issue) {
                    SystemIssue.bluetoothOff => "Bluetooth is off",
                    SystemIssue.locationOff => "Location is off",
                  };

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Color(0xFF1F1F1F), size: 26),
                        const SizedBox(width: 8),
                        Text(
                          message,
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
          final wearableProvider = ref.watch(wearablesProvider);

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
    final provider = ref.read(wearablesProvider);
    provider.setConnecting(device.id, true);

    try {
      final connector = ref.read(wearableConnectorProvider);
      final wearable = await connector.connect(device);

      provider.addWearable(wearable);
      provider.setFailed(device.id, false);
    } catch (e) {
      provider.setFailed(device.id, true);
    } finally {
      provider.setConnecting(device.id, false);
    }
  }

  Future<List<SystemIssue>> _checkSystemStatus() async {
    final provider = ref.read(wearablesProvider);
    final issues = <SystemIssue>[];

    if (!await provider.isBluetoothOn) {
      issues.add(SystemIssue.bluetoothOff);
    }

    if (!await provider.isLocationOn) {
      issues.add(SystemIssue.locationOff);
    }

    return issues;
  }
}

enum SystemIssue {
  bluetoothOff,
  locationOff,
}
