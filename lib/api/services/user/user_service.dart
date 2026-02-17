import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/user/upload_photo_response.dart';
import 'package:openearable/api/services/user/user_endpoints.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

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

  Future<void> deleteUser() async {
    await _dio.delete(UserEndpoints.baseUrl);
  }

  Future<UploadPhotoResponse> requestUploadPermission(
    ContentType contentType,
  ) async {
    final response = await _dio.post(
      UserEndpoints.photo,
      data: {"contentType": contentType.jsonRepresentation},
    );
    return UploadPhotoResponse.fromJson(response.asMap());
  }

  Future<User> completeUpload(String key) async {
    final res = await _dio.put(
      UserEndpoints.photoComplete,
      data: {"key": key},
    );

    final data = res.asMap();
    return User.fromJson(data);
  }

  Future<void> removeAvatar() async {
    await _dio.delete(UserEndpoints.photo);
  }
}
