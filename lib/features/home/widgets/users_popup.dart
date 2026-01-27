import 'package:flutter/material.dart';
import 'package:openearable/features/auth/widgets/auth_button.dart';
import 'package:openearable/features/home/widgets/home_text_field.dart';

import '../../../app/constants/colors.dart';
import '../../../app/theme/text_styles.dart';

enum ProjectRole { editor, viewer }

extension ProjectRoleLabel on ProjectRole {
  String get label {
    switch (this) {
      case ProjectRole.editor:
        return 'Editor';
      case ProjectRole.viewer:
        return 'Viewer';
    }
  }
}

class RoleDropdownPill extends StatelessWidget {
  const RoleDropdownPill({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ProjectRole? value;
  final ValueChanged<ProjectRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            width: 3,
            color: AppColors.fieldBorder,
          ),
        ),

        child: DropdownButtonHideUnderline(
          child: DropdownButton<ProjectRole>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text('Role', style: AuthTextStyles.fieldHint),
            style: AuthTextStyles.fieldInput,
            items: ProjectRole.values
                .map(
                  (r) => DropdownMenuItem<ProjectRole>(
                value: r,
                child: Text(r.label),
              ),
            )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class UsersPopup extends StatefulWidget {
  const UsersPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UsersPopup(),
    );
  }

  @override
  State<UsersPopup> createState() => _UsersPopupState();
}

class _UsersPopupState extends State<UsersPopup> {
  final _emailController = TextEditingController();
  ProjectRole _role = ProjectRole.viewer;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 600,
        height: 700,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Users',
                  style: GlobalTextStyles.cardTitle,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 330,
                      height: 55,
                      child: HomeTextField(
                        controller: _emailController,
                        hint: 'User Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(width: 12),

                    RoleDropdownPill(
                      value: _role,
                      onChanged: (v) => setState(() => _role = v),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: 490,
                  height: 55,
                  child: AuthButton(
                    text: 'Add',
                    onTap: () {
                      // TODO : Add user logic
                    },
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.black12,
                          width: 2,
                        ),
                        bottom: BorderSide(
                          color: Colors.black12,
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: _UsersPlaceholderList(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('‹ Go Back'),
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

class _UsersPlaceholderList extends StatelessWidget {
  const _UsersPlaceholderList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => const _UserCardPlaceholder(),
    );
  }
}

class _UserCardPlaceholder extends StatelessWidget {
  const _UserCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              child: Icon(Icons.person, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'User Name',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'user@email.com',
                    style: TextStyle(color: Colors.black54),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Viewer',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
