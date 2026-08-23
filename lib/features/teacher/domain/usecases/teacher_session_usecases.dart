import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../entities/attendance_record.dart';
import '../entities/circle_session_entities.dart';
import '../repositories/abstract_teacher_repository.dart';

class LoadCircleStudentsUseCase {
  const LoadCircleStudentsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<InstituteUser>> call(String circleId) {
    return _repository.fetchCircleStudents(circleId);
  }
}

class StartTeachingSessionUseCase {
  const StartTeachingSessionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<TeachingSession> call({
    required String circleId,
    required String teacherId,
  }) {
    return _repository.startSession(circleId: circleId, teacherId: teacherId);
  }
}

class EndTeachingSessionUseCase {
  const EndTeachingSessionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<TeachingSession> call(String sessionId) {
    return _repository.endSession(sessionId);
  }
}

class GetOpenSessionUseCase {
  const GetOpenSessionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<TeachingSession?> call(String circleId) {
    return _repository.getOpenSession(circleId);
  }
}

class SaveDailyAttendanceUseCase {
  const SaveDailyAttendanceUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call({
    required TeachingSession session,
    required List<AttendanceRecord> records,
  }) {
    return _repository.saveDailyAttendance(session: session, records: records);
  }
}

class AwardPointsUseCase {
  const AwardPointsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(PointEntry entry) => _repository.awardPoints(entry);
}

class ListQuestionsUseCase {
  const ListQuestionsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<QaQuestion>> call(String circleId) {
    return _repository.listQuestions(circleId);
  }
}

class SaveQuestionUseCase {
  const SaveQuestionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(QaQuestion question) => _repository.saveQuestion(question);
}

class DeleteQuestionUseCase {
  const DeleteQuestionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(String questionId) =>
      _repository.deleteQuestion(questionId);
}

class PickRandomQuestionUseCase {
  const PickRandomQuestionUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<QaQuestion?> call(
    String circleId, {
    QuestionCategory? category,
  }) {
    return _repository.pickRandomQuestion(circleId, category: category);
  }
}

class GetHonorBoardUseCase {
  const GetHonorBoardUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<HonorEntry>> call({
    required String circleId,
    required HonorPeriod period,
    String? openSessionId,
  }) {
    return _repository.getHonorBoard(
      circleId: circleId,
      period: period,
      openSessionId: openSessionId,
    );
  }
}

class GetCircleForTeacherUseCase {
  const GetCircleForTeacherUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<Circle?> call(String teacherId) {
    return _repository.getCircleForTeacher(teacherId);
  }
}

class ListMonthlyPlansUseCase {
  const ListMonthlyPlansUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<MonthlyPlan>> call(String circleId) {
    return _repository.listMonthlyPlans(circleId);
  }
}

class SaveMonthlyPlanUseCase {
  const SaveMonthlyPlanUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(MonthlyPlan plan) {
    return _repository.saveMonthlyPlan(plan);
  }
}

class DeleteMonthlyPlanUseCase {
  const DeleteMonthlyPlanUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(String planId) {
    return _repository.deleteMonthlyPlan(planId);
  }
}

class StudentPointsMapUseCase {
  const StudentPointsMapUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<Map<String, int>> call(String circleId) {
    return _repository.studentPointsMap(circleId);
  }
}

class RemoveStudentFromCircleUseCase {
  const RemoveStudentFromCircleUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call({required String circleId, required String studentId}) {
    return _repository.removeStudentFromCircle(
      circleId: circleId,
      studentId: studentId,
    );
  }
}

class ListSessionReportsUseCase {
  const ListSessionReportsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<SessionReport>> call(String circleId) {
    return _repository.listSessionReports(circleId);
  }
}

class UpdateSessionDetailsUseCase {
  const UpdateSessionDetailsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call({
    required String sessionId,
    required String lessonTitle,
    required int successRate,
    required String startedAt,
    String? endedAt,
  }) {
    return _repository.updateSessionDetails(
      sessionId: sessionId,
      lessonTitle: lessonTitle,
      successRate: successRate,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }
}

class SubmitStudentRequestUseCase {
  const SubmitStudentRequestUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<void> call(StudentJoinRequest request) {
    return _repository.submitStudentRequest(request);
  }
}

class ListMyStudentRequestsUseCase {
  const ListMyStudentRequestsUseCase(this._repository);

  final AbstractTeacherRepository _repository;

  Future<List<StudentJoinRequest>> call({
    required String circleId,
    required String teacherId,
  }) {
    return _repository.listMyStudentRequests(
      circleId: circleId,
      teacherId: teacherId,
    );
  }
}
