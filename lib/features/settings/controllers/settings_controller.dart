import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/auth/state/user_provider.dart';

/// Riverpod provider for [SettingsController], allowing
/// reactive access to account management and user settings logic.
final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

/// Controller for user account management and profile settings.
///
/// Provides functions to delete accounts, refresh user data, upload or
/// remove avatars, and emit toast notifications on success or failure.
/// Uses Riverpod [Ref] to interact with other providers such as session,
/// user, and S3 services.
class SettingsController {
  SettingsController(this.ref);

  final Ref ref;

  /// Deletes the current user account.
  ///
  /// Calls [userServiceProvider.deleteUser] and logs the user out.
  /// If deletion succeeds emits a success toast. Otherwise emits an
  /// error toast and rethrows the exception.
  Future<void> deleteAccount() async {
    try {
      await ref.read(userServiceProvider).deleteUser();
      await ref.read(authControllerProvider).logout();
      ref.read(toastProvider.notifier).state =
      const ToastEvent.success('Account deleted');
    } catch (_) {
      ref.read(toastProvider.notifier).state =
      const ToastEvent.error('Failed to delete account');
      rethrow;
    }
  }

  /// Refreshes the current user data from the server.
  ///
  /// Clears the cached session user, invalidates [userProvider], and waits
  /// for the updated user. If refresh fails emits an error toast.
  Future<void> refreshUser() async {
    try {
      ref.read(sessionProvider.notifier).clearUser();
      ref.invalidate(userProvider);
      await ref.read(userProvider.future);
    } catch (_) {
      ref.read(toastProvider.notifier).state =
      const ToastEvent.error('Failed to refresh user');
      rethrow;
    }
  }

  /// Uploads a new avatar for the current user.
  ///
  /// Uses [userServiceProvider] to request upload permission and [s3ServiceProvider]
  /// to upload the file. Updates the user's session after a successful upload.
  /// If the upload fails then emits an error toast.
  ///
  /// Throws [FileSystemException] if the file does not exist.
  Future<void> uploadAvatar(File file) async {
    final userService = ref.read(userServiceProvider);
    final s3Service = ref.read(s3ServiceProvider);

    try {
      if (!await file.exists()) {
        throw const FileSystemException('Avatar file not found');
      }

      final ext = file.path.split('.').last.toUpperCase();
      final contentType = ContentType.fromString(ext);
      final data = await userService.requestUploadPermission(contentType);

      await s3Service.uploadFile(
        putUrl: data.uploadUrl,
        file: file,
        headers: data.requiredHeaders,
      );

      final updatedUser = await userService.completeUpload(data.key);
      ref.read(sessionProvider.notifier).setUser(updatedUser);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Uploading avatar for user failed: $e");
      }
      emitToast(ref, ToastEvent.error("Photo upload failed"));
    }
  }

  /// Removes the current user's avatar.
  ///
  /// Calls [userServiceProvider.removeAvatar] and refreshes the user session.
  /// If the deletion fails emits an error toast .
  Future<void> removeAvatar() async {
    final userService = ref.read(userServiceProvider);
    try {
      await userService.removeAvatar();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Photo deletion failed: $e");
      }
      emitToast(ref, ToastEvent.error("Failed to remove photo"));
    }

    await refreshUser();
  }
}
