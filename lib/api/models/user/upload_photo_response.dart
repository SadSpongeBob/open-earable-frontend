/// Represents the response returned by the server after requesting a photo upload.
///
/// Contains information necessary to perform the upload, including the URL,
/// unique key, and any HTTP headers required for the request.
///
/// Parameters:
/// - [key]: Unique identifier for the photo upload.
/// - [uploadUrl]: URL to which the photo file should be uploaded.
/// - [requiredHeaders]: Map of HTTP headers required to successfully upload the photo.
class UploadPhotoResponse {
  final String key;
  final String uploadUrl;
  final Map<String, String> requiredHeaders;

  UploadPhotoResponse({
    required this.key,
    required this.uploadUrl,
    required this.requiredHeaders,
  });

  /// Creates an [UploadPhotoResponse] instance from a JSON map returned by the API.
  factory UploadPhotoResponse.fromJson(Map<String, dynamic> json) {
    final String uploadUrl = json['uploadUrl'] as String;
    final String key = json['key'] as String;
    final Map<String, String> headers = Map<String, String>.from(
      json['requiredHeaders'] as Map<String, dynamic>,
    );

    return UploadPhotoResponse(
      key: key,
      uploadUrl: uploadUrl,
      requiredHeaders: headers,
    );
  }
}
