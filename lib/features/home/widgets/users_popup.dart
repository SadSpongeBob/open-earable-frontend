import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/auth/widgets/auth_button.dart';
import 'package:openearable/features/home/widgets/home_text_field.dart';
import '../../../app/constants/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../auth/state/session_provider.dart';
import '../controllers/home_controller.dart';

enum ProjectUserRole { editor, viewer }

extension ProjectRoleLabel on ProjectUserRole {
  String get label {
    switch (this) {
      case ProjectUserRole.editor:
        return 'Editor';
      case ProjectUserRole.viewer:
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

  final ProjectUserRole? value;
  final ValueChanged<ProjectUserRole> onChanged;

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
          child: DropdownButton<ProjectUserRole>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text('Role', style: AuthTextStyles.fieldHint),
            style: AuthTextStyles.fieldInput,
            items: ProjectUserRole.values
                .map(
                  (r) => DropdownMenuItem<ProjectUserRole>(
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

class UsersPopup extends ConsumerStatefulWidget {
  const UsersPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UsersPopup(),
    );
  }

  @override
  ConsumerState<UsersPopup> createState() => _UsersPopupState();
}

class _UsersPopupState extends ConsumerState<UsersPopup> {
  final _emailController = TextEditingController();
  ProjectUserRole _role = ProjectUserRole.viewer;


  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canAdd => _emailController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(homeControllerProvider.notifier);

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
                const Text('Users', style: GlobalTextStyles.cardTitle),
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
                  child: Opacity(
                    opacity: _canAdd ? 1.0 : 0.45,
                    child: IgnorePointer(
                      ignoring: !_canAdd,
                      child: AuthButton(
                        text: 'Add',
                        onTap: () async {
                          final session = ref.read(sessionProvider);
                          final myUserId = session.user?.userId;
                          if (myUserId == null) return;

                          await controller.addUserToOpenProject(
                            myUserId: myUserId,
                            emailAddress: _emailController.text,
                            role: _role == ProjectUserRole.editor ? 'EDITOR' : 'VIEWER',
                          );

                          _emailController.clear();
                          setState(() => _role = ProjectUserRole.viewer);
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black12, width: 2),
                        bottom: BorderSide(color: Colors.black12, width: 2),
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

// Placeholder list and user card for demonstration purposes
// This would be replaced with actual data in a real implementation
// TODO: Implement actual user list fetching and display logic
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
