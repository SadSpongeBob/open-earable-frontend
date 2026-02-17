import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/utils/validators.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/auth/state/user_provider.dart';
import 'package:openearable/features/settings/controllers/settings_controller.dart';
import 'package:openearable/features/settings/widgets/settings_avatar.dart';
import '../../../app/theme/text_styles.dart';
import '../../settings/widgets/download_method_dropdown.dart';
import '../../../app/widgets/user_card.dart';
import '../../../app/widgets/input_box.dart';
import '../widgets/settings_app_bar.dart';

import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _loading = false;
  bool _dirty = false;
  bool _saving = false;
  bool _initialized = false;
  bool _removeAvatarPending = false;
  File? _pendingAvatar;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_markDirty);
    _emailController.addListener(_markDirty);
    _pwController.addListener(_markDirty);
  }

  void _markDirty() {
    final shouldSetDirty = !_dirty;
    setState(() {
      if (shouldSetDirty) _dirty = true;
    });
  }

  bool get _canSave {
    if (_saving || _loading) return false;
    if (!_dirty) return false;

    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;
      PopupToast.show(context, message: next.message);
      ref.read(toastProvider.notifier).state = null;
    });

    final session = ref.watch(sessionProvider);
    final user = ref.watch(userProvider);
    final busy = _saving || _loading || session.isLoading;
    

    return Scaffold(
      appBar: SettingsAppBar(
        loading: _saving,
        canSave: _canSave,
        onBack: () => context.go(Routes.home),
        onSave: _handleChanges,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: UserCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: session.isGuest
                    ? [
                        Image.asset(
                          'assets/images/app_logo.png',
                          width: 90,
                          height: 110,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Guest Account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headerMedium,
                        ),

                        const SizedBox(height: 10),
                        const DownloadMethodDropdown(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: AppTextStyles.footerRegular,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  ref.read(authControllerProvider).logout(),
                              child: Text(
                                "Log In",
                                style: AppTextStyles.footerBold,
                              ),
                            ),
                          ],
                        ),
                      ]
                    : [
                        user.when(
                          data: (u) {
                            if (!_initialized && u != null) {
                              _initializeControllers(u);
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Account',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.headerMedium,
                                ),
                                const SizedBox(height: 10),
                                SettingsAvatar(
                                  avatarUrl: u?.photoUrl,
                                  localFile: _pendingAvatar,
                                  removed: _removeAvatarPending,
                                  onImageSelected: (file) {
                                    setState(() {
                                      _pendingAvatar = file;
                                      _removeAvatarPending = file == null;
                                      _dirty = true;
                                    });
                                  },
                                  refreshUser: () async => ref
                                      .read(settingsControllerProvider)
                                      .refreshUser(),
                                ),
                                const SizedBox(height: 10),
                                InputBox(
                                  controller: _nameController,
                                  hint: 'Enter a new name',
                                  validator: Validators.name,
                                  keyboardType: TextInputType.name,
                                ),
                                const SizedBox(height: 10),
                                InputBox(
                                  controller: _emailController,
                                  hint: 'Enter a new email address',
                                  validator: Validators.email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 10),
                                InputBox(
                                  controller: _pwController,
                                  hint: 'Enter a new password to change',
                                  validator: _pwController.text.isEmpty
                                      ? null
                                      : Validators.password,
                                  obscureText: !_showPassword,
                                  suffixIcon: Transform.translate(
                                    offset: const Offset(-20, 0),
                                    child: IconButton(
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const DownloadMethodDropdown(),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: AppButton.secondary(
                                          text: 'Sign Out',
                                          onPressed: busy
                                              ? null
                                              : ref
                                                    .read(
                                                      authControllerProvider,
                                                    )
                                                    .logout,
                                          textStyle: AppTextStyles.footerMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: AppButton.danger(
                                          text: 'Delete Account',
                                          onPressed: busy
                                              ? null
                                              : _handleDelete,
                                          textStyle: AppTextStyles.footerMedium,
                                          isLoading: _loading,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, st) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('Failed to load user'),
                                const SizedBox(height: 8),
                                AppButton.secondary(
                                  text: 'Retry',
                                  onPressed: () async => ref
                                      .read(settingsControllerProvider)
                                      .refreshUser(),
                                  textStyle: AppTextStyles.footerMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final pw = _pwController.text.trim();

      final settingsController = ref.read(settingsControllerProvider);

      await ref
          .read(authServiceProvider)
          .updateUser(
            name: name,
            emailAddress: email,
            password: pw.isEmpty ? null : pw,
          );
    
      if (_pendingAvatar != null) {
        await settingsController.uploadAvatar(_pendingAvatar!);
      } else if (_removeAvatarPending) {
        await settingsController.removeAvatar();
      }

      if (!mounted) return;

      _pendingAvatar = null;
       _removeAvatarPending = false;
      _pwController.clear();
      setState(() => _dirty = false);

      await settingsController.refreshUser();
      
      ref.read(toastProvider.notifier).state =
      const ToastEvent.success('Profile updated');
    } catch (_) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).state =
      const ToastEvent.error('Failed to update account');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _loading = true);
    try {
      await ref.read(settingsControllerProvider).deleteAccount();
    } catch (_) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).state =
      const ToastEvent.error('Failed to delete account');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initializeControllers(User u) {
    _initialized = true;
    _nameController.text = u.name;
    _emailController.text = u.emailAddress;
  }
}
