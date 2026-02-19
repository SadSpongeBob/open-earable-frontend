import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A utility class that displays a temporary toast-style popup using an [Overlay].
///
/// The toast is shown at the top center of the screen as a pill-shaped message
/// and automatically fades and slides out after the specified [duration].
///
/// Only one toast can be visible at a time. Calling [show] will replace any
/// currently visible toast.
class PopupToast {
  /// The active overlay entry for the currently displayed toast.
  static OverlayEntry? _entry;

  /// Shows a toast popup at the top of the screen.
  ///
  /// The toast is inserted into the root [Overlay] of the given [context],
  /// displayed as an animated pill that fades and slides into view, and
  /// automatically disappears after the provided [duration].
  ///
  /// If another toast is currently visible, it will be removed before showing
  /// the new one.
  ///
  /// Parameters:
  /// - [context]: The build context used to access the root overlay.
  /// - [message]: The text displayed inside the toast pill.
  /// - [duration]: How long the toast remains visible before dismissing.
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (_) => _ToastPill(
        message: message,
        onDone: () {
          _entry?.remove();
          _entry = null;
        },
        duration: duration,
      ),
    );

    overlay.insert(_entry!);
  }
}

/// Internal animated toast widget that handles fade and slide transitions
/// and automatically dismisses itself after the given duration.
class _ToastPill extends StatefulWidget {
  const _ToastPill({
    required this.message,
    required this.onDone,
    required this.duration,
  });

  /// The message displayed inside the toast.
  final String message;

  /// Callback invoked after the exit animation completes.
  final VoidCallback onDone;

  /// The total time the toast remains visible before dismissing.
  final Duration duration;

  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future<void>.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _Pill(message: widget.message),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual pill container used to render the toast message.
class _Pill extends StatelessWidget {
  const _Pill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.fifty,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: AppColors.fiveHundred,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(message, style: AppTextStyles.footerMedium),
      ),
    );
  }
}
