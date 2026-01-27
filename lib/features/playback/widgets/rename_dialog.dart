import 'package:flutter/material.dart';
import 'package:openearable/features/home/widgets/home_text_field.dart';
Future<String?> showRenameDialog(BuildContext context, {required String oldName}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => RenameDialog(oldName: oldName),
  );
}

class RenameDialog extends StatefulWidget {
  final String oldName;
  const RenameDialog({Key? key, required this.oldName}) : super(key: key);

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

  Future<void> _submit() async {
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
        child: Center(
          child: Container(
            width: 400,
            height: 248,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                  child: Center(
                    child: Text(
                      'Rename Video',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 345,
                  height: 55,
                  child: HomeTextField(
                    controller: _controller,
                    hint: 'New name',
                    textAlign: TextAlign.center,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: 400,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _working ? null : _submit,
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.red, fontSize: 25),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 400,
                  height: 50,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontSize: 25)),
                    ),
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
