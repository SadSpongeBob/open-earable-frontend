class UploadPhotoResponse {
  final String key;
  final String uploadUrl;
  final Map<String, String> requiredHeaders;

  UploadPhotoResponse({
    required this.key,
    required this.uploadUrl,
    required this.requiredHeaders,
  });

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
