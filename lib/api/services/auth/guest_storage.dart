import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestStorage {
  static const _kIsGuest = 'is_guest';

  Future<void> setGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsGuest, value);
  }

  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsGuest) ?? false;
  }

  Future<void> clear() => setGuest(false);
}

final guestStorageProvider = Provider<GuestStorage>((ref) => GuestStorage());
