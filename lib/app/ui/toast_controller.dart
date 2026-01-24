import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'toast_event.dart';

final toastProvider = StateProvider<ToastEvent?>((_) => null);

void emitToast(Ref ref, ToastEvent event) {
  ref.read(toastProvider.notifier).state = event;
}
