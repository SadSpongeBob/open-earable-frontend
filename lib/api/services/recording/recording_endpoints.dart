/// Provides API endpoint paths for recording-related operations.
///
/// All paths are relative to the API base URL.
class RecordingEndpoints {
  static const String base = '/api/recording';

  static String recording(String recordingId) => '$base/$recordingId';
  static String complete(String recordingId) => '$base/$recordingId/complete';
  static String deleteRecording(String recordingId) => '$base/$recordingId/delete';

  static String rename(String recordingId) => '$base/$recordingId';


  static String duplicate(String recordingId) => '$base/$recordingId/duplicate';

  static String projectRecordings(String projectId) => '$base/project/$projectId';

  static String userRecordings(String userId) => '$base/user/$userId';

}
