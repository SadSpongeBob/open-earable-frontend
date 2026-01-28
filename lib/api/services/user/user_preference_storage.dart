import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceStorage {
  static const _kIsWifiOnly = 'is_wifi_only';

  Future<void> setWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsWifiOnly, value);
  }

  Future<bool> isWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsWifiOnly) ?? false;
  }
}

final userPreferenceStorage = Provider<UserPreferenceStorage>((ref) => UserPreferenceStorage());
