import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'toast_event.dart';

/// A global [StateProvider] that holds the latest [ToastEvent] to be displayed.
///
/// When a new event is assigned, UI listeners can react and show a toast
/// message accordingly. The state is nullable and reset after consumption.
final toastProvider = StateProvider<ToastEvent?>((_) => null);

/// Emits a new [ToastEvent] to the [toastProvider].
///
/// This function updates the provider state, which can be observed by UI
/// components responsible for displaying toast messages.
///
/// Parameters:
/// - [ref]: The Riverpod [Ref] used to access the provider.
/// - [event]: The toast event that should be displayed.
void emitToast(Ref ref, ToastEvent event) {
  ref.read(toastProvider.notifier).state = event;
}
