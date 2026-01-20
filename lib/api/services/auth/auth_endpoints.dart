class AuthEndpoints {
  static const login = "/api/auth/authentication";
  static const register = "/api/auth/register";
  static const refresh = "/api/auth/refresh";

  static String resetPassword(String emailAddress) {
    return "/api/auth/$emailAddress/reset-password";
  }
}
