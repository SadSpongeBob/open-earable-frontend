/// Represents a set of authentication tokens for a user.
///
/// Parameters:
/// - [accessToken]: The access token used for authorizing API requests.
/// - [refreshToken]: The refresh token used to obtain a new access token when the current one expires.
class Tokens {
  final String accessToken;
  final String refreshToken;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
  });

  /// Creates a [Tokens] instance from a JSON map.
  ///
  /// Expects the JSON map to contain [accessToken] and [refreshToken] keys.
  /// Throws a [TypeError] if the keys are missing or of the wrong type.
  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}