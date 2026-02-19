import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/user/upload_photo_response.dart';
import 'package:openearable/api/services/user/user_endpoints.dart';

/// Service class for interacting with user-related API endpoints.
///
/// Provides methods for fetching user information, updating the user’s avatar,
/// and deleting the user account.
class UserService {
  final Dio _dio;

  UserService(this._dio);

  /// Fetches the currently authenticated user.
  ///
  /// If [authToken] is provided, it overrides the default authentication token.
  ///
  /// Returns a [User] object representing the user data.
  Future<User> getUser({String? authToken}) async {
    Options? options;
    if (authToken != null && authToken.isNotEmpty) {
      options = Options(extra: {'authTokenOverride': authToken});
    }

    final res = await _dio.get(UserEndpoints.baseUrl, options: options);

    final data = res.asMap();
    final user = User.fromJson(data);
    return user;
  }

  /// Deletes the currently authenticated user account.
  ///
  /// Throws an exception if the request fails.
  Future<void> deleteUser() async {
    await _dio.delete(UserEndpoints.baseUrl);
  }

  /// Requests permission to upload a user avatar.
  ///
  /// [contentType] specifies the type of file being uploaded (e.g., JPEG, PNG).
  ///
  /// Returns an [UploadPhotoResponse] containing temporary credentials or upload URL.
  Future<UploadPhotoResponse> requestUploadPermission(
    ContentType contentType,
  ) async {
    final response = await _dio.post(
      UserEndpoints.photo,
      data: {"contentType": contentType.jsonRepresentation},
    );
    return UploadPhotoResponse.fromJson(response.asMap());
  }

  /// Completes the avatar upload after a successful file upload.
  ///
  /// [key] is the identifier returned from the upload permission request.
  ///
  /// Returns the updated [User] object with the new avatar.
  Future<User> completeUpload(String key) async {
    final res = await _dio.put(
      UserEndpoints.photoComplete,
      data: {"key": key},
    );

    final data = res.asMap();
    return User.fromJson(data);
  }

  /// Removes the user’s avatar.
  Future<void> removeAvatar() async {
    await _dio.delete(UserEndpoints.photo);
  }
}
