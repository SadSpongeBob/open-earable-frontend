import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
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
}
