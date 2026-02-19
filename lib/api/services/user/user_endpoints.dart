/// A collection of user-related API endpoint paths.
///
/// This class centralizes all user endpoints used in the app to avoid
/// hardcoding URLs in multiple places.
class UserEndpoints {
  static const baseUrl = "/api/user";
  static const photo = "$baseUrl/photo";
  static const photoComplete = "$baseUrl/photo/complete";
}