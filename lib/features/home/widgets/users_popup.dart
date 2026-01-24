import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../api/models/auth/user.dart';
import '../../../api/models/project_role.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_text_field.dart';

class UsersPopup extends ConsumerWidget {
  const UsersPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final TextEditingController _emailController = TextEditingController();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 520,
        height: 720,
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              'Users',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),

            // top inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: HomeTextField(
                      value: state.usersEmailInput,
                      onChanged: controller.setUsersEmailInput, controller: _emailController, hint: '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _RoleDropdown(
                      value: state.usersSelectedRole,
                      onChanged: controller.setUsersSelectedRole,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isUsersLoading
                      ? null
                      : () => controller.addUserToOpenProject(),
                  child: state.isUsersLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Add'),
                ),
              ),
            ),

            if (state.usersErrorMessage != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.usersErrorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // users list
            Expanded(
              child: state.isUsersLoading && state.projectUsers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                itemCount: state.projectUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final user = state.projectUsers[index];
                  return _UserCard(
                    user: user,
                    onRoleChanged: user.isMe
                        ? null
                        : (role) => controller.changeUserRole(
                      userId: user.id,
                      role: role,
                    ),
                    onRemove: user.isMe
                        ? null
                        : () => controller.removeUser(userId: user.id),
                  );
                },
              ),
            ),

            // bottom "go back"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('‹ Go Back'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.onChanged,
  });

  final ProjectRole value;
  final ValueChanged<ProjectRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProjectRole>(
      value: value,
      items: ProjectRole.values
          .map(
            (r) => DropdownMenuItem(
          value: r,
          child: Text(r.label),
        ),
      )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final User user;
  final ValueChanged<ProjectRole>? onRoleChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.isMe ? '${user.name} (You)' : user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),

                  // Role: dropdown when editable, plain text otherwise
                  if (onRoleChanged == null)
                    Text(
                      user.role.label,
                      style: const TextStyle(color: Colors.black54),
                    )
                  else
                    DropdownButton<ProjectRole>(
                      value: user.role,
                      underline: const SizedBox.shrink(),
                      items: ProjectRole.values
                          .map(
                            (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onRoleChanged!(v);
                      },
                    ),
                ],
              ),
            ),

            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
