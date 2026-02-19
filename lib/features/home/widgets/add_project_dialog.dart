import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/widgets/input_box.dart';

/// Dialog for creating a new project.
///
/// Returns the entered project name when confirmed,
/// or `null` if the dialog is dismissed.
class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key, this.initialName = ''});

  final String initialName;

  /// Displays the dialog and returns the entered project name.
  ///
  /// [initialName] can be provided to pre-fill the input field.
  /// Returns `null` if the dialog is closed without confirmation.
  static Future<String?> show(BuildContext context, {String initialName = ''}) {
    return showAppDialog(
      context,
      dialog: AddProjectDialog(initialName: initialName),
    );
  }

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
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

  /// Validates the input and closes the dialog with the project name.
  Future<void> _handleAdd() async {
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
      title: 'Add Project',
      width: 400,
      body: SizedBox(
        width: 345,
        height: 55,
        child: InputBox(
          controller: _controller,
          hint: 'Project Name',
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _focus.unfocus(),
        ),
      ),
      actions: [
        BaseDialogActionRow(
          child: AppButton.dangerGhost(
            text: 'Add',
            onPressed: _working ? null : _handleAdd,
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
