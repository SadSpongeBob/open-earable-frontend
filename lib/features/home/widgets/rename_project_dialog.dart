import 'package:flutter/material.dart';
import 'home_text_field.dart';

class RenameProjectDialog extends StatefulWidget {
  const RenameProjectDialog({
    super.key,
    this.initialName = '',
    this.onRename,
  });

  final String initialName;
  final void Function(String newName)? onRename;

  static Future<void> show(
      BuildContext context, {
        String initialName = '',
        void Function(String)? onRename,
      }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: RenameProjectDialog(
          initialName: initialName,
          onRename: onRename,
        ),
      ),
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

  Future<void> _handleRename() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _working = true);
    try {
      widget.onRename?.call(name);
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 356,
          height: 307,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
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
                  child: HomeTextField(
                    controller: _controller,
                    hint: 'Project name',
                    textAlign: TextAlign.center,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_working) return;
                      _handleRename();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

