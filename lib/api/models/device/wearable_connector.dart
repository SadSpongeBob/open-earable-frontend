import 'dart:async';
import 'package:open_earable_flutter/open_earable_flutter.dart';

abstract class WearableEvent {
  final Wearable wearable;
  WearableEvent(this.wearable);
}

abstract class WearableConnectionEvent extends WearableEvent {
  WearableConnectionEvent(super.wearable);
}

final class WearableConnectEvent extends WearableConnectionEvent {
  WearableConnectEvent(super.wearable);
}

enum DisconnectReason {
  user, system
}

final class WearableDisconnectedEvent extends WearableConnectionEvent {
  final DisconnectReason disconnectReason;
  WearableDisconnectedEvent(this.disconnectReason, super.wearable);
}

final class WearableStereoPairedEvent extends WearableEvent {
  final Wearable partner;
  WearableStereoPairedEvent(this.partner, super.wearable);
}


/// This class handles all connections with wearables and notifies subscribers over Wearable events
class WearableConnector {
  final WearableManager _wm;

  final _events = StreamController<WearableEvent>.broadcast();
  Stream<WearableEvent> get events => _events.stream;

  WearableConnector([WearableManager? wm]) : _wm = wm ?? WearableManager();

  Future<Wearable> connect(DiscoveredDevice device) async {
    final wearable = await _wm.connectToDevice(device);
    _handleConnection(wearable);
    return wearable;
  }

  void _handleConnection(Wearable wearable) {
    wearable.addDisconnectListener(() {
      _events.add(WearableDisconnectedEvent(DisconnectReason.system, wearable));
    });
    _events.add(WearableConnectEvent(wearable));
  }
}
