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

  Map<String, dynamic> data;
  try {
    data = await userService.requestUploadPermission(contentType);
  } catch (e) {
    throw Exception("STAGE 1 FAIL (Permission): $e");
  }

  final String uploadUrl = data['uploadUrl'];
  final String key = data['key'];
  final Map<String, String> headers =
      Map<String, String>.from(data['requiredHeaders']);

  try {
    await s3Service.uploadFile(
      putUrl: uploadUrl,
      file: file,
      headers: headers,
    );
  } catch (e) {
    throw Exception("STAGE 2 FAIL (S3 Put): $e");
  }

  try {
    final updatedUser = await userService.completeUpload(key);
    ref.read(sessionProvider.notifier).setUser(updatedUser);
  } catch (e) {
    throw Exception("STAGE 3 FAIL (Complete): $e");
  }
}


  Future<void> removeAvatar() async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.removeAvatar();

    if (response.statusCode != 204) {
      throw Exception("Failed to remove photo");
    }

    await refreshUser();
  }
}
