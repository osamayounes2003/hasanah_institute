import '../entities/institute_entities.dart';

abstract interface class InstituteRepository {
  Future<void> saveCircle(Circle circle);
  Future<void> assignStudentToCircle({
    required String circleId,
    required String studentId,
  });
  Future<void> saveAttendance(AttendanceRecord record);
  Future<void> saveEvaluation(Evaluation evaluation);
  Future<List<Evaluation>> getStudentEvaluations(String studentId);
}
