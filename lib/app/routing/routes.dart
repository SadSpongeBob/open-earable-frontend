class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String recording = '/recording';
  static const String playbackBase = '/playback';

  static String playback(bool isCloud, String recordingId) {
    final source = isCloud ? 'cloud' : 'local';
    return '$playbackBase/$source/$recordingId';
  }

  static const String settings = '/settings';
  static const String export = '/export';
  static const String sensordata = '/sensordata';
  static const String resetPassword = '/reset-password';
  static const String requestResetPassword = '/request-reset-password';
}
