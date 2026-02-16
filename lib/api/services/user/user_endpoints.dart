class UserEndpoints {
  static const baseUrl = "/api/user";
  static const photo = "$baseUrl/photo";
  static String photoComplete(String key) => "$baseUrl/photo/$key/complete";
}