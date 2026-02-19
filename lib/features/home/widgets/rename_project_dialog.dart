import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/widgets/input_box.dart';

/// Dialog for renaming a project.
/// 
/// Displays an input field pre-filled with [initialName] and returns
/// the new name when the user confirms. Includes "Ok" and "Close" actions.
class RenameProjectDialog extends StatefulWidget {
  const RenameProjectDialog({super.key, this.initialName = ''});

  /// The initial project name to populate the input box.
  final String initialName;

  /// Shows the rename dialog and returns the new project name if confirmed.
  static Future<String?> show(BuildContext context, {String initialName = ''}) {
    return showAppDialog(
      context,
      dialog: RenameProjectDialog(initialName: initialName),
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

  /// Handles submitting the new project name and closing the dialog.
  Future<void> _submitRename() async {
    if (_working) return;

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
    return BaseDialog(
      body: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Image.asset('assets/images/folder.png', fit: BoxFit.contain),
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
              onSubmitted: (_) => {_submitRename},
            ),
          ),
        ],
      ),
      actions: [
        BaseDialogActionRow(
          child: AppButton.dangerGhost(
            text: 'Ok',
            onPressed: _working ? null : _submitRename,
            borderRadius: 0,
          ),
        ),
        BaseDialogActionRow(
          topBorder: false,
          bottomRounded: true,
          child: AppButton.ghost(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            borderRadius: 0,
          ),
        ),
      ],
    );
  }
}
