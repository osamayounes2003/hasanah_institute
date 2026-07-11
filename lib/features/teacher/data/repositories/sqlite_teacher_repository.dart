import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/evaluation_record.dart';
import '../../domain/repositories/abstract_teacher_repository.dart';
import '../datasources/local_teacher_data_source.dart';

class SqliteTeacherRepository implements AbstractTeacherRepository {
  const SqliteTeacherRepository(this._localDataSource);

  final LocalTeacherDataSource _localDataSource;

  @override
  Future<List<InstituteUser>> fetchCircleStudents(String circleId) async {
    final rows = await _localDataSource.circleStudents(circleId);
    return rows.map(_userFromRow).toList();
  }

  @override
  Future<void> insertDailyEvaluations(List<EvaluationRecord> evaluations) {
    return _localDataSource.insertEvaluationBatch(
      evaluations.map(_evaluationToRow).toList(),
    );
  }

  @override
  Future<void> saveAttendanceList(List<AttendanceRecord> records) {
    return _localDataSource.saveAttendanceBatch(
      records.map(_attendanceToRow).toList(),
    );
  }

  Map<String, Object?> _attendanceToRow(AttendanceRecord record) {
    return {
      'id': record.id,
      'student_id': record.studentId,
      'circle_id': record.circleId,
      'attendance_at': record.attendanceAt,
      'status': record.status.name,
      'created_at': record.createdAt,
      'updated_at': record.updatedAt,
    };
  }

  Map<String, Object?> _evaluationToRow(EvaluationRecord evaluation) {
    return {
      'id': evaluation.id,
      'student_id': evaluation.studentId,
      'circle_id': evaluation.circleId,
      'evaluated_at': evaluation.evaluatedAt,
      'new_hifz_score': evaluation.newHifzScore,
      'close_review_score': evaluation.closeReviewScore,
      'distant_review_score': evaluation.distantReviewScore,
      'notes': evaluation.notes,
      'created_at': evaluation.createdAt,
      'updated_at': evaluation.updatedAt,
    };
  }

  InstituteUser _userFromRow(Map<String, Object?> row) {
    return InstituteUser(
      id: row['id']! as String,
      name: row['name']! as String,
      role: UserRole.values.byName(row['role']! as String),
      parentId: row['parent_id'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    );
  }
}
