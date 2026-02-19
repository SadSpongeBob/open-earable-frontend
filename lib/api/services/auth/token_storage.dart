import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';

/// Secure storage for authentication tokens.
///
/// Uses [FlutterSecureStorage] to persist and retrieve access and refresh tokens.
/// Provides methods to save, read, and clear tokens.
class TokenStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage();

  /// Saves access and refresh tokens securely.
  ///
  /// [tokens] The [Tokens] object containing accessToken and refreshToken.
  Future<void> saveTokens(Tokens tokens) async {
    await _storage.write(key: _kAccessToken, value: tokens.accessToken);
    await _storage.write(key: _kRefreshToken, value: tokens.refreshToken);
  }

  /// Reads the stored access token.
  ///
  /// Returns the access token string, or `null` if not set.
  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  /// Reads the stored refresh token.
  ///
  /// Returns the refresh token string, or `null` if not set.
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  /// Reads both access and refresh tokens.
  ///
  /// Returns a [Tokens] object if both tokens exist, otherwise `null`.
  Future<Tokens?> readTokens() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    if (access == null || refresh == null) return null;
    return Tokens(accessToken: access, refreshToken: refresh);
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }
}
