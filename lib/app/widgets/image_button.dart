import 'package:flutter/material.dart';

class ImageButton extends StatefulWidget  {
  final GlobalKey? buttonKey;
  final String image;
  final String activeImage;
  final Duration pressDuration;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final bool isActive;

  const ImageButton({
    super.key,
    this.buttonKey,
    required this.image,
    required this.activeImage,
    required this.onPressed,
    required this.width,
    required this.height,
    this.pressDuration = const Duration(milliseconds: 100),
    this.isActive = false,
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

    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        key: widget.buttonKey,
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.image, fit: BoxFit.contain,),

            AnimatedOpacity(
              opacity: showActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: Image.asset(
                widget.activeImage,
                fit: BoxFit.contain,
              ),
            )
          ],
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