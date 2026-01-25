import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
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
}
