import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/auth/user.dart';
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

  Future<Map<String, dynamic>> requestUploadPermission(String contentType) async {
    final response = await _dio.post(UserEndpoints.photo, data: {
      "contentType": contentType,
    });
    return response.data['data'];
  }

  Future<Response> completeUpload(String key) async {
    return await _dio.put(
      UserEndpoints.photoComplete(key),
      data: {"key": key},
    );
  }

  Future<Response> removeAvatar() async {
    return await _dio.delete(UserEndpoints.photo);
  }
}
