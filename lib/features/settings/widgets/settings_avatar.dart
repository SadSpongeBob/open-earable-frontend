import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/widgets/pill_menu.dart';
import 'package:openearable/app/constants/colors.dart';

class SettingsAvatar extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final File? localFile;
  final bool removed;
  final Function(File?) onImageSelected;

  const SettingsAvatar({
    super.key,
    required this.avatarUrl,
    required this.localFile,
    required this.removed,
    required this.onImageSelected,
    required Future<void> Function() refreshUser,
  });

  @override
  ConsumerState<SettingsAvatar> createState() => _SettingsAvatarState();
}

class _SettingsAvatarState extends ConsumerState<SettingsAvatar> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final bool hasRemoteImage = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    final bool hasLocalImage = widget.localFile != null;
    
    ImageProvider imageProvider;

    if (hasLocalImage) {
      imageProvider = FileImage(widget.localFile!);
    } else if (widget.removed) {
      imageProvider = const AssetImage("assets/images/user.png");
    } else if (hasRemoteImage) {
      imageProvider = NetworkImage(widget.avatarUrl!);
    } else {
      imageProvider = const AssetImage("assets/images/user.png");
    }

    return PillMenuAnchor<String>(
      value: 'avatar', 
      options: (hasLocalImage || (hasRemoteImage && !widget.removed))
              ? const ['Upload', 'Remove'] 
              : const ['Upload'],
      labelOf: (opt) => opt,
      onChanged: (opt) async {
        if (opt == 'Upload') {
          final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            widget.onImageSelected(File(pickedFile.path));
          }
        } else if (opt == 'Remove') {
          widget.onImageSelected(null);
        }
      },
      childBuilder: (context, isOpen) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              backgroundImage: imageProvider,
            ),
            if (hasLocalImage)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
              ),
          ],
        );
      },
    );
  }
}
