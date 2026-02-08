import 'package:flutter/material.dart';
import 'package:openearable/app/widgets/input_box.dart';
import '../../../app/theme/text_styles.dart';

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({
    super.key,
    this.initialName = '',
  });

  final String initialName;

  static Future<String?> show(BuildContext context, {String initialName = ''}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: AddProjectDialog(initialName: initialName),
      ),
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

  Future<void> _handleAdd() async {
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
    return Material(
      color: Colors.transparent,
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
                    'Add Project',
                    style: AppTextStyles.subheaderBold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: 345,
                height: 55,
                child: InputBox(
                  controller: _controller,
                  hint: 'Project Name',
                  focusNode: _focus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _focus.unfocus();
                  },
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
                    onPressed: _working ? null : _handleAdd,
                    child: const Text(
                      'Add',
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
                    child: Text('Close', style: TextStyle(color: Colors.grey[700], fontSize: 25)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
