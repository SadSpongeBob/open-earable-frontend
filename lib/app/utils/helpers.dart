import 'package:uuid/uuid.dart';

/// Utility helper methods used across the application.
///
/// Provides standardized ID generation for domain entities such as
/// projects, recordings, and sensor data using UUID v6.
class Helpers {
  static const _uuid = Uuid();

  /// Generates a unique identifier for a project.
  ///
  /// The ID is prefixed with `prj_` followed by a UUID v6 string to
  /// ensure chronological ordering and uniqueness.
  static String getProjectId() => "prj_${_uuid.v6()}";

  /// Generates a unique identifier for a recording.
  ///
  /// The ID is prefixed with `rcd_` followed by a UUID v6 string.
  static String getRecordingId() => "rcd_${_uuid.v6()}";

  /// Generates a unique identifier for sensor data entries.
  ///
  /// The ID is prefixed with `sns_` followed by a UUID v6 string.
  static String getSensorDataId() => "sns_${_uuid.v6()}";
}
