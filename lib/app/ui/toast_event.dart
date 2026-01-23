import 'package:flutter/foundation.dart';

enum ToastKind { success, error }

@immutable
class ToastEvent {
  final ToastKind kind;
  final String message;

  const ToastEvent.success(this.message) : kind = ToastKind.success;
  const ToastEvent.error(this.message) : kind = ToastKind.error;
}
