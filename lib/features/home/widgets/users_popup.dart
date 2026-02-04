import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openearable/features/auth/widgets/auth_button.dart';
import 'package:openearable/features/home/widgets/home_text_field.dart';

import '../../../api/models/project/project_role.dart';
import '../../../api/models/project/project_user.dart';
import '../../../app/constants/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../auth/state/session_provider.dart';
import '../controllers/home_controller.dart';
import '../state/home_state.dart';
import '../state/home_provider.dart';

enum RoleChoice { viewer, editor }

extension _RoleChoiceX on RoleChoice {
  String get label => this == RoleChoice.editor ? 'Editor' : 'Viewer';

  ProjectRole toProjectRole() =>
      this == RoleChoice.editor ? Editor(userId: '') : Viewer(userId: '');
}

class RoleDropdownPill extends StatelessWidget {
  const RoleDropdownPill({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RoleChoice value;
  final ValueChanged<RoleChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(width: 3, color: AppColors.fieldBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RoleChoice>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            style: AuthTextStyles.fieldInput,
            items: RoleChoice.values
                .map(
                  (r) => DropdownMenuItem<RoleChoice>(
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
  RoleChoice _role = RoleChoice.viewer;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));

    Future.microtask(() async {
      final session = ref.read(sessionProvider);
      final myUserId = session.user?.userId;
      if (myUserId == null) return;

      await ref.read(homeControllerProvider).loadUsersForOpenProject(
        myUserId: myUserId,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _canAdd(bool isUsersLoading) =>
      _emailController.text.trim().isNotEmpty && !isUsersLoading;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(homeControllerProvider);
    final HomeState state = ref.watch(homeStateProvider);

    final session = ref.watch(sessionProvider);
    final myUserId = session.user?.userId;

    final users = state.projectUsers;
    final canAdd = _canAdd(state.isUsersLoading);
    final canManage = myUserId != null &&
        users.any((u) => u.userId == myUserId && u.role is Owner);

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 550,
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

                if (canManage) ...[
                  // input row
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

                  // add button
                  SizedBox(
                    width: 490,
                    height: 55,
                    child: Opacity(
                      opacity: canAdd ? 1.0 : 0.45,
                      child: IgnorePointer(
                        ignoring: !canAdd,
                        child: AuthButton(
                          text: 'Add',
                          onTap: () async {
                            await controller.addUserToOpenProject(
                              myUserId: myUserId,
                              emailAddress: _emailController.text,
                              role: _role.toProjectRole(),
                            );

                            _emailController.clear();
                            setState(() => _role = RoleChoice.viewer);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],

                // list
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black12, width: 2),
                        bottom: BorderSide(color: Colors.black12, width: 2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: state.isUsersLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _UsersList(
                        users: users,
                        myUserId: myUserId,
                        canManage: canManage,
                        onRemove: (userId) async {
                          if (myUserId == null) return;
                          await controller.removeUserFromOpenProject(
                            myUserId: myUserId,
                            userId: userId,
                          );
                        },
                      ),
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

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.myUserId,
    required this.canManage,
    required this.onRemove,
  });

  final List<ProjectUser> users;
  final String? myUserId;
  final bool canManage;
  final Future<void> Function(String userId) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _UserCard(
        user: users[i],
        myUserId: myUserId,
        canManage: canManage,
        onRemove: onRemove,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.myUserId,
    required this.canManage,
    required this.onRemove,
  });

  final ProjectUser user;
  final String? myUserId;
  final bool canManage;
  final Future<void> Function(String userId) onRemove;

  @override
  Widget build(BuildContext context) {
    final isMe = myUserId != null && user.userId == myUserId;

    final showRemove = canManage && !isMe;

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
            CircleAvatar(
              radius: 26,
              backgroundImage:
              user.pictureUrl == null ? null : NetworkImage(user.pictureUrl!),
              child: user.pictureUrl == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.emailAddress,
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _roleLabel(user.role),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (showRemove)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onRemove(user.userId),
              ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(ProjectRole role) {
    if (role is Owner) return 'Owner';
    if (role is Editor) return 'Editor';
    return 'Viewer';
  }
}
