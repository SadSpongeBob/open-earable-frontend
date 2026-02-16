import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/widgets/pill_menu.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/settings/controllers/settings_controller.dart';

class SettingsAvatar extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final Future<void> Function() refreshUser;

  const SettingsAvatar({
    super.key,
    required this.avatarUrl,
    required this.refreshUser,
  });

  @override
  ConsumerState<SettingsAvatar> createState() => _SettingsAvatarState();
}

class _SettingsAvatarState extends ConsumerState<SettingsAvatar> {
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final url = widget.avatarUrl;
    final bool hasImage = url != null && url.isNotEmpty;

    return PillMenuAnchor<String>(
      value: 'avatar_menu',
      options: hasImage ? const ['Upload', 'Remove'] : const ['Upload'],
      labelOf: (opt) => opt,
      onChanged: (opt) async {
        if (opt == 'Upload') {
          await _pickAndUploadImage();
        } else if (opt == 'Remove') {
          await _removeAvatar();
        }
      },
      childBuilder: (context, isOpen) {
        return CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary,
          backgroundImage: hasImage
              ? NetworkImage(url)
              : const AssetImage("assets/images/user.png") as ImageProvider,
          child: _uploading
              ? const CircularProgressIndicator(strokeWidth: 3)
              : null,
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _uploading = true);

    try {
      final file = File(pickedFile.path);

      await ref.read(settingsControllerProvider).uploadAvatar(file);

      if (mounted) {
        ref.read(toastProvider.notifier).state = 
            const ToastEvent.success("Profile photo updated");
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).state = const ToastEvent.success("Upload failed");
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploading = true);
    try {
      await ref.read(settingsControllerProvider).removeAvatar();

      if (mounted) {
        ref.read(toastProvider.notifier).state = 
            const ToastEvent.success("Profile photo removed");
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).state = 
            const ToastEvent.success("Failed to remove photo");
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
