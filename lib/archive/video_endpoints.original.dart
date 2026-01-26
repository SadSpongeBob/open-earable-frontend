// Archivkopie von video_endpoints.dart
// Original-Inhalt gesichert bevor die Datei als ungenutzt markiert wurde.
class VideoEndpoints {
  static const String base = '/api/video';

  static const String videos = base;

  static String video(String videoId) => '$base/$videoId';

  static String projectVideos(String projectId) => '$base/project/$projectId';

  static String deleteVideo(String videoId) => '$base/$videoId/delete';

  static const String upload = '$base/upload';
}
