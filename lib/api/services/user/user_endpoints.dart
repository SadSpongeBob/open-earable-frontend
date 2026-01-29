class UserEndpoints {
  static const baseUrl = "/api/user";

  static String byEmail(String email) => '$baseUrl/by-email?email=${Uri.encodeComponent(email)}';
}