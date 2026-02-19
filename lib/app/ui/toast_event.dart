import 'package:flutter/foundation.dart';

/// The type of toast to display.
///
/// Determines the visual styling and semantic meaning of the toast,
/// such as success or error feedback.
enum ToastKind { success, error }

/// Represents a toast notification event emitted by the application.
///
/// A [ToastEvent] contains the message to display and its [ToastKind],
/// which allows the UI to render different styles (e.g. success or error).
@immutable
class ToastEvent {
  /// The semantic type of the toast (e.g. success or error).
  final ToastKind kind;

  /// The message that will be shown in the toast UI.
  final String message;

  const ToastEvent.success(this.message) : kind = ToastKind.success;
  const ToastEvent.error(this.message) : kind = ToastKind.error;
}
