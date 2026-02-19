import 'package:flutter/material.dart';

/// A customizable button that displays an image, with an optional active image overlay.
///
/// [ImageButton] can display two images: a default `image` and an `activeImage`
/// that appears while the button is pressed or when `isActive` is true.
/// It supports tap and long-press gestures and provides built-in press animation
/// using a short duration opacity effect.
///
/// Parameters:
/// - [buttonKey]: Optional key for the button widget.
/// - [image]: The default image to display when the button is inactive.
/// - [activeImage]: The image to display when the button is pressed or active.
/// - [onPressed]: Callback invoked when the button is tapped.
/// - [onLongPress]: Optional callback invoked on long press.
/// - [width]: Width of the button.
/// - [height]: Height of the button.
/// - [pressDuration]: Duration of the press animation (default: 100ms).
/// - [isActive]: Whether the button should show the active state initially (default: false).
/// - [semanticLabel]: Accessibility label for screen readers.
class ImageButton extends StatefulWidget  {
  final GlobalKey? buttonKey;
  final String image;
  final String activeImage;
  final Duration pressDuration;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double width;
  final double height;
  final bool isActive;
  final String semanticLabel;

  const ImageButton({
    super.key,
    this.buttonKey,
    required this.image,
    required this.activeImage,
    required this.onPressed,
    this.onLongPress,
    required this.width,
    required this.height,
    this.pressDuration = const Duration(milliseconds: 100),
    this.isActive = false,
    required this.semanticLabel,
  });

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  bool _isPressed = false;
  bool _isLocked = false;

  @override
  Widget build(BuildContext context) {
     bool showActive = _isPressed || widget.isActive;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: true,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
        child: SizedBox(
          key: widget.buttonKey,
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.image, 
                fit: BoxFit.contain, 
                excludeFromSemantics: true,
              ),

              AnimatedOpacity(
                opacity: showActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: Image.asset(
                  widget.activeImage,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (_isLocked) return;

    _isLocked = true;
    setState(() => _isPressed = true);
    await Future.delayed(widget.pressDuration);

    if (!mounted) return;

    setState(() => _isPressed = false);
    _isLocked = false;

    widget.onPressed();
  }
}