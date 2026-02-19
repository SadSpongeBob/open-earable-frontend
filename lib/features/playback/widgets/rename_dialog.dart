import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/dialog.dart';
import 'package:openearable/app/widgets/input_box.dart';

/// A dialog widget that allows the user to rename a video.
///
/// Displays a text input initialized with [oldName] and provides "Ok" and "Close" actions.
///
/// Parameters:
/// - [oldName]: The current name of the video to prefill the input field.
class RenameDialog extends StatefulWidget {
  final String oldName;

  const RenameDialog({super.key, required this.oldName});

  /// Shows the rename dialog and returns the new name entered by the user.
  ///
  /// Parameters:
  /// - [context]: The BuildContext to display the dialog.
  /// - [oldName]: The current name of the video to prefill the input.
  ///
  /// Returns:
  /// - A [Future<String?>] that completes with the new name if "Ok" is pressed,
  ///   or null if the dialog is closed without confirmation.
  static Future<String?> show(BuildContext context, {required String oldName}) {
    return showAppDialog(context, dialog: RenameDialog(oldName: oldName));
  }

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.oldName);
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

  /// Handles submission of the new name.
  ///
  /// - Trims whitespace from the input.
  /// - Ignores submission if the input is empty or already working.
  /// - Closes the dialog and returns the new name via Navigator.pop.
  Future<void> _submit() async {
    if (_working) return;

    final name = _controller.text.trim();

    if (name.isEmpty) return;
    setState(() => _working = true);

    _focus.unfocus();

    try {
      Navigator.of(context).pop(name);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Rename Video',
      body: InputBox(
        controller: _controller,
        hint: 'New Name',
        focusNode: _focus,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        BaseDialogActionRow(
          child: AppButton.dangerGhost(
            text: 'Ok',
            onPressed: _working ? null : _submit,
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
