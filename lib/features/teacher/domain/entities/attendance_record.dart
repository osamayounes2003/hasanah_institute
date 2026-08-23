import '../../../shared/domain/entities/institute_entities.dart';

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.circleId,
    required this.attendanceDate,
    required this.attendanceAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
  }) : assert(_isUtcIso8601(attendanceAt)),
       assert(_isUtcIso8601(createdAt)),
       assert(_isUtcIso8601(updatedAt)),
       assert(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(attendanceDate));

  final String id;
  final String studentId;
  final String circleId;
  final String? sessionId;
  final String attendanceDate;
  final String attendanceAt;
  final AttendanceStatus status;
  final String createdAt;
  final String updatedAt;

  static bool _isUtcIso8601(String value) {
    return value.endsWith('Z') && DateTime.tryParse(value)?.isUtc == true;
  }
}
