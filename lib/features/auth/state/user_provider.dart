import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/features/auth/state/session_provider.dart';

final userProvider = FutureProvider<User?>((ref) async {
  final session = ref.watch(sessionProvider);

  if (session.isGuest) return null;

  final cached = session.user;
  if (cached != null) return cached;

  final user = await ref.read(userServiceProvider).getUser();

  ref.read(sessionProvider.notifier).setUser(user);
  return user;
});
