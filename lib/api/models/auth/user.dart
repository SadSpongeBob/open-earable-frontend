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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      name: json['name'] as String,
      emailAddress: json['emailAddress'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': userId,
    'name': name,
    'emailAddress': emailAddress,
    'photoUrl': photoUrl,
  };


}