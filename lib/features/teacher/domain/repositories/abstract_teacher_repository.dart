import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../entities/attendance_record.dart';
import '../entities/circle_session_entities.dart';

abstract interface class AbstractTeacherRepository {
  Future<Circle?> getCircleForTeacher(String teacherId);

  Future<List<InstituteUser>> fetchCircleStudents(String circleId);

  Future<TeachingSession?> getOpenSession(String circleId);

  Future<TeachingSession?> getSessionForDate({
    required String circleId,
    required String sessionDate,
  });

  Future<TeachingSession> startSession({
    required String circleId,
    required String teacherId,
  });

  Future<TeachingSession> endSession(String sessionId);

  Future<void> updateSessionDetails({
    required String sessionId,
    required String lessonTitle,
    required int successRate,
    required String startedAt,
    String? endedAt,
  });

  Future<List<SessionReport>> listSessionReports(String circleId);

  /// Saves checkbox attendance once per day and awards +1 point for present.
  Future<void> saveDailyAttendance({
    required TeachingSession session,
    required List<AttendanceRecord> records,
  });

  Future<void> awardPoints(PointEntry entry);

  Future<List<QaQuestion>> listQuestions(String circleId);

  Future<void> saveQuestion(QaQuestion question);

  Future<void> deleteQuestion(String questionId);

  Future<QaQuestion?> pickRandomQuestion(
    String circleId, {
    QuestionCategory? category,
    QuestionPool pool = QuestionPool.bank,
  });

  Future<int> promoteDailyQuestionsToBank(String circleId);

  Future<InstituteUser> addStudentToCircle({
    required String circleId,
    required String studentName,
  });

  Future<List<HonorEntry>> getHonorBoard({
    required String circleId,
    required HonorPeriod period,
    String? openSessionId,
  });

  Future<List<MonthlyPlan>> listMonthlyPlans(String circleId);

  Future<void> saveMonthlyPlan(MonthlyPlan plan);

  Future<void> deleteMonthlyPlan(String planId);

  Future<Map<String, int>> studentPointsMap(String circleId);

  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  });

  Future<void> submitStudentRequest(StudentJoinRequest request);

  Future<List<StudentJoinRequest>> listMyStudentRequests({
    required String circleId,
    required String teacherId,
  });
}
