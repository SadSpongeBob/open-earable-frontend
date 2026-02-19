/// Centralized definition of all application route paths.
///
/// This class provides string constants and helper methods used by
/// the navigation system (e.g., GoRouter) to ensure consistent and
/// type-safe route usage across the app.
class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String recording = '/recording';
  static const String playbackBase = '/playback';

  /// Builds a playback route path with dynamic source and recording ID.
  ///
  /// [isCloud] determines the recording source segment (`cloud` or `local`).
  /// [recordingId] is the unique identifier of the recording to be played.
  static String playback(bool isCloud, String recordingId) {
    final source = isCloud ? 'cloud' : 'local';
    return '$playbackBase/$source/$recordingId';
  }

  static const String settings = '/settings';
  static const String export = '/export';
  static const String sensordata = '/sensordata';
  static const String sensordataDetails = '/sensordata-details';
  static const String sensorPlayback = '/sensor-playback';
  static const String resetPassword = '/reset-password';
  static const String requestResetPassword = '/request-reset-password';
}
