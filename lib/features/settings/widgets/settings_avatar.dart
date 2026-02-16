import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/app/widgets/pill_menu.dart';
import 'package:openearable/app/ui/popup_toast.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/api/services/user/user_endpoints.dart';

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
      value: null,
      // Only show 'Remove' if there is actually an image
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
          backgroundColor: Colors.grey[200],
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
      final dio = ref.read(apiDioProvider);
      final s3Service = ref.read(s3ServiceProvider);

      // Determine Content Type
      final ext = pickedFile.path.split('.').last.toUpperCase();
      final contentType = (ext == 'PNG') ? 'PNG' : 'JPEG';

      // Request Permission
      final initResponse = await dio.post(UserEndpoints.photo, data: {
        "contentType": contentType,
      });
      
      final data = initResponse.data['data'];
      final String uploadUrl = data['uploadUrl'];
      final String key = data['key'];
      final Map<String, String> headers = Map<String, String>.from(data['requiredHeaders']);

      // S3 Upload
      await s3Service.uploadFile(
        putUrl: uploadUrl,
        file: File(pickedFile.path),
        headers: headers,
      );

      // Complete handshake
      final completeResponse = await dio.put(
        UserEndpoints.photoComplete(key),
        data: {"key": key},
      );

      if (completeResponse.statusCode == 200 && mounted) {
        await widget.refreshUser();
        if (mounted) PopupToast.show(context, message: "Profile photo updated");
      }
    } catch (e) {
      if (mounted) PopupToast.show(context, message: "Upload failed");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploading = true);
    try {
      final dio = ref.read(apiDioProvider);
      final response = await dio.delete(UserEndpoints.photo);

      if (response.statusCode == 204 && mounted) {
        await widget.refreshUser();
        if (mounted) PopupToast.show(context, message: "Profile photo removed");
      }
    } catch (e) {
      if (mounted) PopupToast.show(context, message: "Failed to remove photo");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
