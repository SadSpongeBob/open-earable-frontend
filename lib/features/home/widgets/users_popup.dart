import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/widgets/pill_menu.dart';
import 'package:openearable/app/widgets/input_box.dart';

import '../../../api/models/project/project_role.dart';
import '../../../api/models/project/project_user.dart';
import '../../../app/constants/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/widgets/in_line_menu.dart';
import '../../auth/state/session_provider.dart';
import '../controllers/home_controller.dart';
import '../state/home_state.dart';
import '../state/home_provider.dart';

enum RoleChoice { editor, viewer }

extension _RoleChoiceX on RoleChoice {
  String get label => this == RoleChoice.editor ? 'Editor' : 'Viewer';

  ProjectRoleType toRoleType() =>
      this == RoleChoice.editor ? ProjectRoleType.editor : ProjectRoleType.viewer;
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

      await ref
          .read(homeControllerProvider)
          .loadUsersForOpenProject(myUserId: myUserId);
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
            color: AppColors.fifty,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Text('Users', style: AppTextStyles.headerBold),
                const SizedBox(height: 18),

                if (canManage) ...[
                  // input row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 330,
                        height: 55,
                        child: InputBox(
                          controller: _emailController,
                          hint: 'User Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        height: 55,
                        child: PillMenu<RoleChoice>(
                          value: _role,
                          options: RoleChoice.values,
                          labelOf: (r) => r.label,
                          onChanged: (v) => setState(() => _role = v),
                        ),
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
                        child: AppButton.primary(
                          text: 'Add',
                          onPressed: () async {
                            await controller.addUserToOpenProject(
                              myUserId: myUserId,
                              emailAddress: _emailController.text,
                              role: _role.toRoleType(),
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
                        top: BorderSide(color: AppColors.fourHundred, width: 2),
                        bottom: BorderSide(
                          color: AppColors.fourHundred,
                          width: 2,
                        ),
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
                  child: AppButton.ghost(
                    text: 'Go Back',
                    onPressed: () => Navigator.of(context).pop(),
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
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users in this project yet',
          style: AppTextStyles.footerMedium,
        ),
      );
    }

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

class _UserCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = myUserId != null && user.userId == myUserId;

    final showRemove = canManage && !isMe;

    final showRoleDropdown =
        canManage && !isMe && user.role is! Owner;

    final controller = ref.read(homeControllerProvider);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AppColors.fifty,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.fifty,
              radius: 26,
              child: user.pictureUrl == null
                  ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                  : Image.network(user.pictureUrl!, width: 40, height: 40),
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
                          style: AppTextStyles.footerBold,
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
                            color: AppColors.twoHundred,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'You',
                            style: AppTextStyles.footerBold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.emailAddress,
                    style: AppTextStyles.footerMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  showRoleDropdown
                      ? InlineMenu<ProjectRoleType>(
                    value: user.role is Editor ? ProjectRoleType.editor : ProjectRoleType.viewer,
                    options: const [
                      ProjectRoleType.viewer,
                      ProjectRoleType.editor,
                    ],
                    labelOf: (r) => r.label,
                    menuWidth : 100,
                    onChanged: (next) async {
                      await controller.updateUserRoleForOpenProject(
                        myUserId: myUserId,
                        userId: user.userId,
                        role: next,
                      );
                    },
                  )
                      : Text(
                    user.role.label,
                    style: AppTextStyles.footerMedium,
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
}
