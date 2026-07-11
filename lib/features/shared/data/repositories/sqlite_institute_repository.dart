import '../../../../core/utils/iso_date_time.dart';
import '../../domain/entities/institute_entities.dart';
import '../../domain/repositories/institute_repository.dart';
import '../datasources/local_institute_data_source.dart';

class SqliteInstituteRepository implements InstituteRepository {
  const SqliteInstituteRepository(this._localDataSource);

  final LocalInstituteDataSource _localDataSource;

  @override
  Future<void> assignStudentToCircle({
    required String circleId,
    required String studentId,
  }) {
    return _localDataSource.insertCircleStudent({
      'circle_id': circleId,
      'student_id': studentId,
      'created_at': IsoDateTime.encode(DateTime.now()),
    });
  }

  @override
  Future<List<Evaluation>> getStudentEvaluations(String studentId) async {
    final rows = await _localDataSource.evaluationsForStudent(studentId);
    return rows.map(_evaluationFromRow).toList();
  }

  @override
  Future<void> saveAttendance(AttendanceRecord record) {
    return _localDataSource.insertAttendance({
      'id': record.id,
      'student_id': record.studentId,
      'circle_id': record.circleId,
      'attendance_at': IsoDateTime.encode(record.attendanceAt),
      'status': record.status.name,
      'created_at': IsoDateTime.encode(record.createdAt),
      'updated_at': IsoDateTime.encode(record.updatedAt),
    });
  }

  @override
  Future<void> saveCircle(Circle circle) {
    return _localDataSource.insertCircle({
      'id': circle.id,
      'name': circle.name,
      'teacher_id': circle.teacherId,
      'created_at': IsoDateTime.encode(circle.createdAt),
      'updated_at': IsoDateTime.encode(circle.updatedAt),
    });
  }

  @override
  Future<void> saveEvaluation(Evaluation evaluation) {
    return _localDataSource.insertEvaluation({
      'id': evaluation.id,
      'student_id': evaluation.studentId,
      'evaluated_at': IsoDateTime.encode(evaluation.evaluatedAt),
      'new_hifz_score': evaluation.newHifzScore,
      'close_review_score': evaluation.closeReviewScore,
      'distant_review_score': evaluation.distantReviewScore,
      'notes': evaluation.notes,
      'created_at': IsoDateTime.encode(evaluation.createdAt),
      'updated_at': IsoDateTime.encode(evaluation.updatedAt),
    });
  }

  Evaluation _evaluationFromRow(Map<String, Object?> row) {
    return Evaluation(
      id: row['id']! as String,
      studentId: row['student_id']! as String,
      evaluatedAt: IsoDateTime.decode(row['evaluated_at']! as String),
      newHifzScore: row['new_hifz_score']! as double,
      closeReviewScore: row['close_review_score']! as double,
      distantReviewScore: row['distant_review_score']! as double,
      notes: row['notes'] as String?,
      createdAt: IsoDateTime.decode(row['created_at']! as String),
      updatedAt: IsoDateTime.decode(row['updated_at']! as String),
    );
  }
}
