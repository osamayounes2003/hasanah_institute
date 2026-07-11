import '../../../shared/domain/entities/institute_entities.dart';

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.circleId,
    required this.attendanceAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(_isUtcIso8601(attendanceAt)),
       assert(_isUtcIso8601(createdAt)),
       assert(_isUtcIso8601(updatedAt));

  final String id;
  final String studentId;
  final String circleId;
  final String attendanceAt;
  final AttendanceStatus status;
  final String createdAt;
  final String updatedAt;

  static bool _isUtcIso8601(String value) {
    return value.endsWith('Z') && DateTime.tryParse(value)?.isUtc == true;
  }
}
