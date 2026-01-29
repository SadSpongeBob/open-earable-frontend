import 'package:uuid/uuid.dart';

class Helpers {
  static const _uuid = Uuid();

  static String getProjectId() => "prj_${_uuid.v6()}";

  static String getRecordingId() => "rcd_${_uuid.v6()}";
}
