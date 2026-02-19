/// Represents a user in the system.
///
/// Parameters:
/// - [userId]: The unique identifier of the user.
/// - [name]: The user's name.
/// - [emailAddress]: The user's email address.
/// - [photoUrl]: Optional URL to the user's profile photo.
class User {
  final String userId;
  final String name;
  final String emailAddress;
  final String? photoUrl;

  User({
    required this.userId,
    required this.name,
    required this.emailAddress,
    required this.photoUrl,
  });

  /// Creates a [User] instance from a JSON map.
  ///
  /// Expects the JSON map to contain [userId], [name], [emailAddress],
  /// and optionally [photoUrl].
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
