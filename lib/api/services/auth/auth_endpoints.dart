class AuthEndpoints {
  static const baseUrl = "/api/auth";
  static const login = "$baseUrl/authentication";
  static const register = "$baseUrl/register";
  static const refresh = "$baseUrl/refresh";
  static const update = "$baseUrl/update";
  static const resetPasswordSuffix = '/reset-password';

  static String resetPassword(String emailAddress) {
    return "$baseUrl/$emailAddress/$resetPasswordSuffix";
  }
}
