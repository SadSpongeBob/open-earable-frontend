import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple storage service for managing guest user status.
///
/// Uses [SharedPreferences] to persist whether the current user is
/// a guest. Provides methods to set, check, and clear the guest status.
class GuestStorage {
  static const _kIsGuest = 'is_guest';

  /// Sets whether the current user is a guest.
  ///
  /// [value] `true` to mark the user as a guest, `false` otherwise.
  Future<void> setGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsGuest, value);
  }

  /// Returns whether the current user is a guest.
  ///
  /// Returns `true` if the user is a guest, `false` otherwise (default).
  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsGuest) ?? false;
  }

  /// Clears the guest status by marking the user as not a guest.
  Future<void> clear() => setGuest(false);
}

/// Riverpod provider for accessing [GuestStorage].
final guestStorageProvider = Provider<GuestStorage>((ref) => GuestStorage());
