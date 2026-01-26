
class RecordingEndpoints {

  static const String base = '/api/recording';


  static const String recordings = base;

  static String recording(String recordingId) => '$base/$recordingId';


  static const String startUpload = recordings;


  static String complete(String recordingId) => '$base/$recordingId/complete';

  static String upload() => '$base/upload';


  static String deleteRecording(String recordingId) => '$base/$recordingId/delete';

  static String rename(String recordingId) => '$base/$recordingId/rename';


  static String duplicate(String recordingId) => '$base/$recordingId/duplicate';

  static String projectRecordings(String projectId) => '$base/project/$projectId';

  static String userRecordings(String userId) => '$base/user/$userId';


  static const String qPage = 'page';
  static const String qSize = 'size';
  static const String qSort = 'sort';
  static const String qProjectId = 'projectId';
  static const String qSearch = 'search';
}
