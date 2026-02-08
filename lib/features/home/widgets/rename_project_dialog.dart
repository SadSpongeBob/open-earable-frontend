import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/input_box.dart';

class RenameProjectDialog extends StatefulWidget {
  const RenameProjectDialog({super.key, this.initialName = ''});

  final String initialName;

  static Future<String?> show(BuildContext context, {String initialName = ''}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => RenameProjectDialog(initialName: initialName),
    );
  }

  @override
  State<RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<RenameProjectDialog> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submitRename() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _working = true);
    try {
      Navigator.of(context).pop(name);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 356,
            height: 307,
            decoration: BoxDecoration(
              color: AppColors.fifty,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.fiveHundred,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/images/folder.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 300,
                    height: 55,
                    child: InputBox(
                      controller: _controller,
                      hint: 'Project Name',
                      focusNode: _focus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_working) return;
                        _submitRename();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
