import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/auth/state/user_provider.dart';

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

class SettingsController {
  SettingsController(this.ref);
  final Ref ref;

  Future<void> deleteAccount() async {
    await ref.read(userServiceProvider).deleteUser();
    await ref.read(authControllerProvider).logout();
  }

  Future<void> refreshUser() async {
    ref.read(sessionProvider.notifier).clearUser();
    ref.invalidate(userProvider);
    await ref.read(userProvider.future);
  }

  Future<void> uploadAvatar(File file) async {
    final userService = ref.read(userServiceProvider);
    final s3Service = ref.read(s3ServiceProvider);

    final ext = file.path.split('.').last.toUpperCase();
    final contentType = (ext == 'PNG') ? 'PNG' : 'JPEG';

    final data = await userService.requestUploadPermission(contentType);

    final String uploadUrl = data['uploadUrl'];
    final String key = data['key'];
    final Map<String, String> headers =
        Map<String, String>.from(data['requiredHeaders']);

    await s3Service.uploadFile(
      putUrl: uploadUrl,
      file: file,
      headers: headers,
    );

    final response = await userService.completeUpload(key);

    if (response.statusCode != 200) {
      throw Exception("Upload handshake failed");
    }

    await refreshUser();
  }

  Future<void> removeAvatar() async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.removeAvatar();

    if (response.statusCode != 204) {
      throw Exception("Failed to remove avatar");
    }

    await refreshUser();
  }
}
