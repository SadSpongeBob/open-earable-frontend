import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple wrapper around [SharedPreferences] for storing user preferences.
///
/// It manages the "Wi-Fi only" setting, which indicates
/// whether the app should perform certain network operations only on Wi-Fi.
class UserPreferenceStorage {
  /// Key used to store the Wi-Fi only preference.
  static const _kIsWifiOnly = 'is_wifi_only';

  /// Saves the user's Wi-Fi only preference.
  ///
  /// [value] determines whether network operations should be limited to Wi-Fi.
  Future<void> setWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsWifiOnly, value);
  }

  /// Returns whether the user has enabled Wi-Fi only mode.
  ///
  /// Defaults to `false` if the preference has not been set.
  Future<bool> isWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsWifiOnly) ?? false;
  }
}

/// A provider that exposes a singleton [UserPreferenceStorage] instance.
final userPreferenceStorage = Provider<UserPreferenceStorage>((ref) => UserPreferenceStorage());

/// A [FutureProvider] that exposes the current Wi-Fi only preference.
///
/// Consumers can use this to reactively determine whether network
/// operations should be limited to Wi-Fi.
final wifiOnlyProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(userPreferenceStorage);
  return storage.isWifiOnly();
});

