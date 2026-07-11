import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../entities/attendance_record.dart';
import '../entities/evaluation_record.dart';

abstract interface class AbstractTeacherRepository {
  Future<List<InstituteUser>> fetchCircleStudents(String circleId);

  /// Persists a complete attendance grid as a single transaction.
  Future<void> saveAttendanceList(List<AttendanceRecord> records);

  /// Persists the session's triple-ledger evaluations as a single transaction.
  Future<void> insertDailyEvaluations(List<EvaluationRecord> evaluations);
}
