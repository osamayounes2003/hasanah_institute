import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/circle_session_entities.dart';
import '../../domain/usecases/teacher_session_usecases.dart';

enum CircleSessionUiStatus { initial, loading, saving, success, failure }

class CircleSessionState {
  const CircleSessionState({
    this.status = CircleSessionUiStatus.initial,
    this.students = const [],
    this.studentPoints = const {},
    this.session,
    this.questions = const [],
    this.monthlyPlans = const [],
    this.sessionReports = const [],
    this.studentRequests = const [],
    this.honorBoard = const [],
    this.honorPeriod = HonorPeriod.daily,
    this.randomQuestion,
    this.message,
  });

  final CircleSessionUiStatus status;
  final List<InstituteUser> students;
  final Map<String, int> studentPoints;
  final TeachingSession? session;
  final List<QaQuestion> questions;
  final List<MonthlyPlan> monthlyPlans;
  final List<SessionReport> sessionReports;
  final List<StudentJoinRequest> studentRequests;
  final List<HonorEntry> honorBoard;
  final HonorPeriod honorPeriod;
  final QaQuestion? randomQuestion;
  final String? message;

  CircleSessionState copyWith({
    CircleSessionUiStatus? status,
    List<InstituteUser>? students,
    Map<String, int>? studentPoints,
    TeachingSession? session,
    List<QaQuestion>? questions,
    List<MonthlyPlan>? monthlyPlans,
    List<SessionReport>? sessionReports,
    List<StudentJoinRequest>? studentRequests,
    List<HonorEntry>? honorBoard,
    HonorPeriod? honorPeriod,
    QaQuestion? randomQuestion,
    String? message,
    bool clearSession = false,
    bool clearRandomQuestion = false,
    bool clearMessage = false,
  }) {
    return CircleSessionState(
      status: status ?? this.status,
      students: students ?? this.students,
      studentPoints: studentPoints ?? this.studentPoints,
      session: clearSession ? null : session ?? this.session,
      questions: questions ?? this.questions,
      monthlyPlans: monthlyPlans ?? this.monthlyPlans,
      sessionReports: sessionReports ?? this.sessionReports,
      studentRequests: studentRequests ?? this.studentRequests,
      honorBoard: honorBoard ?? this.honorBoard,
      honorPeriod: honorPeriod ?? this.honorPeriod,
      randomQuestion: clearRandomQuestion
          ? null
          : randomQuestion ?? this.randomQuestion,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class CircleSessionCubit extends Cubit<CircleSessionState> {
  CircleSessionCubit({
    required this.loadCircleStudentsUseCase,
    required this.getOpenSessionUseCase,
    required this.startTeachingSessionUseCase,
    required this.endTeachingSessionUseCase,
    required this.saveDailyAttendanceUseCase,
    required this.awardPointsUseCase,
    required this.listQuestionsUseCase,
    required this.saveQuestionUseCase,
    required this.deleteQuestionUseCase,
    required this.pickRandomQuestionUseCase,
    required this.getHonorBoardUseCase,
    required this.listMonthlyPlansUseCase,
    required this.saveMonthlyPlanUseCase,
    required this.deleteMonthlyPlanUseCase,
    required this.studentPointsMapUseCase,
    required this.removeStudentFromCircleUseCase,
    required this.listSessionReportsUseCase,
    required this.updateSessionDetailsUseCase,
    required this.submitStudentRequestUseCase,
    required this.listMyStudentRequestsUseCase,
  }) : super(const CircleSessionState());

  final LoadCircleStudentsUseCase loadCircleStudentsUseCase;
  final GetOpenSessionUseCase getOpenSessionUseCase;
  final StartTeachingSessionUseCase startTeachingSessionUseCase;
  final EndTeachingSessionUseCase endTeachingSessionUseCase;
  final SaveDailyAttendanceUseCase saveDailyAttendanceUseCase;
  final AwardPointsUseCase awardPointsUseCase;
  final ListQuestionsUseCase listQuestionsUseCase;
  final SaveQuestionUseCase saveQuestionUseCase;
  final DeleteQuestionUseCase deleteQuestionUseCase;
  final PickRandomQuestionUseCase pickRandomQuestionUseCase;
  final GetHonorBoardUseCase getHonorBoardUseCase;
  final ListMonthlyPlansUseCase listMonthlyPlansUseCase;
  final SaveMonthlyPlanUseCase saveMonthlyPlanUseCase;
  final DeleteMonthlyPlanUseCase deleteMonthlyPlanUseCase;
  final StudentPointsMapUseCase studentPointsMapUseCase;
  final RemoveStudentFromCircleUseCase removeStudentFromCircleUseCase;
  final ListSessionReportsUseCase listSessionReportsUseCase;
  final UpdateSessionDetailsUseCase updateSessionDetailsUseCase;
  final SubmitStudentRequestUseCase submitStudentRequestUseCase;
  final ListMyStudentRequestsUseCase listMyStudentRequestsUseCase;

  /// Loads circle data. Does NOT auto-start a session — teacher starts manually.
  Future<void> bootstrap({
    required String circleId,
    required String teacherId,
  }) async {
    emit(
      state.copyWith(status: CircleSessionUiStatus.loading, clearMessage: true),
    );
    try {
      final students = await loadCircleStudentsUseCase(circleId);
      final session = await getOpenSessionUseCase(circleId);
      final questions = await listQuestionsUseCase(circleId);
      final plans = await listMonthlyPlansUseCase(circleId);
      final points = await studentPointsMapUseCase(circleId);
      final reports = await listSessionReportsUseCase(circleId);
      final requests = await listMyStudentRequestsUseCase(
        circleId: circleId,
        teacherId: teacherId,
      );
      final honor = await getHonorBoardUseCase(
        circleId: circleId,
        period: state.honorPeriod,
        openSessionId: session?.isOpen == true ? session!.id : null,
      );
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          students: students,
          studentPoints: points,
          session: session,
          clearSession: session == null,
          questions: questions,
          monthlyPlans: plans,
          sessionReports: reports,
          studentRequests: requests,
          honorBoard: honor,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر تحميل بيانات الحلقة.',
        ),
      );
    }
  }

  Future<void> refreshPoints(String circleId) async {
    final points = await studentPointsMapUseCase(circleId);
    final openId =
        state.session?.isOpen == true ? state.session!.id : null;
    final honor = await getHonorBoardUseCase(
      circleId: circleId,
      period: state.honorPeriod,
      openSessionId: openId,
    );
    emit(state.copyWith(studentPoints: points, honorBoard: honor));
  }

  Future<void> startSession({
    required String circleId,
    required String teacherId,
  }) async {
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final session = await startTeachingSessionUseCase(
        circleId: circleId,
        teacherId: teacherId,
      );
      final reports = await listSessionReportsUseCase(circleId);
      final honor = await getHonorBoardUseCase(
        circleId: circleId,
        period: state.honorPeriod,
        openSessionId: session.id,
      );
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          session: session,
          sessionReports: reports,
          honorBoard: honor,
          message: 'تم بدء الجلسة. كل العمليات تُسجَّل ضمنها.',
        ),
      );
    } on StateError catch (error) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر بدء الجلسة.',
        ),
      );
    }
  }

  Future<void> endSession() async {
    final session = state.session;
    if (session == null) return;
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final closed = await endTeachingSessionUseCase(session.id);
      final reports = await listSessionReportsUseCase(closed.circleId);
      final honor = await getHonorBoardUseCase(
        circleId: closed.circleId,
        period: state.honorPeriod,
        openSessionId: null,
      );
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          session: closed,
          sessionReports: reports,
          honorBoard: honor,
          message: 'تم إنهاء الجلسة.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر إنهاء الجلسة.',
        ),
      );
    }
  }

  Future<void> saveAttendance({
    required String circleId,
    required Set<String> presentStudentIds,
  }) async {
    final session = state.session;
    if (session == null || !session.isOpen) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'ابدأ الجلسة أولاً قبل تسجيل الحضور.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final records = [
        for (final student in state.students)
          AttendanceRecord(
            id: 'attendance-${student.id}-${session.id}',
            studentId: student.id,
            circleId: circleId,
            sessionId: session.id,
            attendanceDate: session.sessionDate,
            attendanceAt: now,
            status: presentStudentIds.contains(student.id)
                ? AttendanceStatus.present
                : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          ),
      ];
      await saveDailyAttendanceUseCase(session: session, records: records);
      await refreshPoints(circleId);
      final reports = await listSessionReportsUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          sessionReports: reports,
          message: 'تم حفظ الحضور واحتساب نقاط الحاضرين.',
        ),
      );
    } on StateError catch (error) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر حفظ الحضور (قد يكون مسجّلاً لهذا اليوم).',
        ),
      );
    }
  }

  Future<void> awardPointsToStudent({
    required String circleId,
    required String studentId,
    required int points,
    required PointReason reason,
    String? note,
  }) async {
    if (points < 1) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'أدخل عدداً صحيحاً من النقاط (1 فأكثر).',
        ),
      );
      return;
    }
    final session = state.session;
    if (session == null || !session.isOpen) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'إسناد النقاط يتم داخل جلسة مفتوحة فقط.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await awardPointsUseCase(
        PointEntry(
          id: 'point-$studentId-${now.hashCode}',
          studentId: studentId,
          circleId: circleId,
          sessionId: session.id,
          points: points,
          reason: reason,
          note: note,
          awardedAt: now,
          createdAt: now,
        ),
      );
      await refreshPoints(circleId);
      final reports = await listSessionReportsUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          sessionReports: reports,
          message: 'تم إسناد $points نقطة.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر إسناد النقاط.',
        ),
      );
    }
  }

  Future<void> addQuestion({
    required String circleId,
    required String teacherId,
    required String question,
    required String answer,
    required QuestionCategory category,
  }) async {
    if (question.trim().isEmpty || answer.trim().isEmpty) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'أدخل السؤال والجواب معاً.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await saveQuestionUseCase(
        QaQuestion(
          id: 'q-$circleId-${now.hashCode}',
          circleId: circleId,
          question: question.trim(),
          answer: answer.trim(),
          category: category,
          createdBy: teacherId,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final questions = await listQuestionsUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          questions: questions,
          message: 'تمت إضافة السؤال.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر حفظ السؤال.',
        ),
      );
    }
  }

  Future<void> removeQuestion(String questionId, String circleId) async {
    try {
      await deleteQuestionUseCase(questionId);
      final questions = await listQuestionsUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          questions: questions,
          message: 'تم حذف السؤال.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر حذف السؤال.',
        ),
      );
    }
  }

  Future<QaQuestion?> spinQuestionWheel(
    String circleId, {
    required QuestionCategory category,
  }) async {
    emit(
      state.copyWith(status: CircleSessionUiStatus.loading, clearMessage: true),
    );
    try {
      final question = await pickRandomQuestionUseCase(
        circleId,
        category: category,
      );
      if (question == null) {
        emit(
          state.copyWith(
            status: CircleSessionUiStatus.failure,
            message: 'لا توجد أسئلة في تصنيف «${category.label}».',
            clearRandomQuestion: true,
          ),
        );
        return null;
      }
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          randomQuestion: question,
        ),
      );
      return question;
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر اختيار سؤال من العجلة.',
        ),
      );
      return null;
    }
  }

  Future<bool> saveMonthlyPlan({
    required String circleId,
    required String teacherId,
    required String title,
    required int plannedLessonsCount,
    required List<PlanLessonItem> lessons,
  }) async {
    if (title.trim().isEmpty) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'أدخل عنوان الخطة.',
        ),
      );
      return false;
    }
    if (plannedLessonsCount < 1) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'عدد الدروس يجب أن يكون 1 فأكثر.',
        ),
      );
      return false;
    }
    if (lessons.length != plannedLessonsCount) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'أدخل عنوان وتاريخ لكل درس مقرّر.',
        ),
      );
      return false;
    }
    if (lessons.any((l) => l.title.trim().isEmpty || l.date.trim().isEmpty)) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'كل درس يحتاج عنواناً وتاريخاً.',
        ),
      );
      return false;
    }
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final nowUtc = DateTime.now().toUtc();
      final now = nowUtc.toIso8601String();
      final plan = MonthlyPlan(
        id: 'plan_${nowUtc.millisecondsSinceEpoch}',
        circleId: circleId,
        title: title.trim(),
        plannedLessonsCount: plannedLessonsCount,
        lessons: lessons,
        createdBy: teacherId,
        createdAt: now,
        updatedAt: now,
      );
      await saveMonthlyPlanUseCase(plan);
      final plans = await listMonthlyPlansUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          monthlyPlans: plans,
          message: 'تم حفظ الخطة الشهرية.',
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر حفظ الخطة الشهرية.',
        ),
      );
      return false;
    }
  }

  Future<void> deleteMonthlyPlan(String planId, String circleId) async {
    try {
      await deleteMonthlyPlanUseCase(planId);
      final plans = await listMonthlyPlansUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          monthlyPlans: plans,
          message: 'تم حذف الخطة.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر حذف الخطة.',
        ),
      );
    }
  }

  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) async {
    try {
      await removeStudentFromCircleUseCase(
        circleId: circleId,
        studentId: studentId,
      );
      final students = await loadCircleStudentsUseCase(circleId);
      final points = await studentPointsMapUseCase(circleId);
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          students: students,
          studentPoints: points,
          message: 'تم إزالة الطالب من الحلقة.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر إزالة الطالب.',
        ),
      );
    }
  }

  Future<void> loadHonorBoard({
    required String circleId,
    required HonorPeriod period,
  }) async {
    emit(
      state.copyWith(
        status: CircleSessionUiStatus.loading,
        honorPeriod: period,
        clearMessage: true,
      ),
    );
    try {
      final openId =
          state.session?.isOpen == true ? state.session!.id : null;
      final honor = await getHonorBoardUseCase(
        circleId: circleId,
        period: period,
        openSessionId: openId,
      );
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          honorBoard: honor,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر تحميل لوحة الشرف.',
        ),
      );
    }
  }

  Future<void> loadSessionReports(String circleId) async {
    try {
      final reports = await listSessionReportsUseCase(circleId);
      emit(state.copyWith(sessionReports: reports));
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر تحميل تقارير الجلسات.',
        ),
      );
    }
  }

  Future<void> updateSessionMeta({
    required String circleId,
    required String sessionId,
    required String lessonTitle,
    required int successRate,
    required String startedAt,
    String? endedAt,
  }) async {
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      await updateSessionDetailsUseCase(
        sessionId: sessionId,
        lessonTitle: lessonTitle,
        successRate: successRate,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      final reports = await listSessionReportsUseCase(circleId);
      TeachingSession? current = state.session;
      if (current?.id == sessionId) {
        final startDate = startedAt.length >= 10
            ? startedAt.substring(0, 10)
            : startedAt;
        current = TeachingSession(
          id: current!.id,
          circleId: current.circleId,
          teacherId: current.teacherId,
          sessionDate: startDate,
          startedAt: startedAt,
          endedAt: endedAt,
          status: current.status,
          createdAt: current.createdAt,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
          lessonTitle: lessonTitle.trim(),
          successRate: successRate.clamp(0, 100),
        );
      }
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          sessionReports: reports,
          session: current,
          message: 'تم تحديث بيانات الجلسة.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر تحديث بيانات الجلسة.',
        ),
      );
    }
  }

  Future<void> requestAddStudent({
    required String circleId,
    required String circleName,
    required String teacherId,
    required String teacherName,
    required String studentName,
  }) async {
    if (studentName.trim().isEmpty) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'أدخل اسم الطالب الثلاثي.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: CircleSessionUiStatus.saving, clearMessage: true),
    );
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await submitStudentRequestUseCase(
        StudentJoinRequest(
          id: 'req_${DateTime.now().millisecondsSinceEpoch}',
          studentName: studentName.trim(),
          circleId: circleId,
          circleName: circleName,
          teacherId: teacherId,
          teacherName: teacherName,
          status: StudentRequestStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final requests = await listMyStudentRequestsUseCase(
        circleId: circleId,
        teacherId: teacherId,
      );
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.success,
          studentRequests: requests,
          message: 'تم إرسال طلب إضافة الطالب وسينتظر موافقة المدير.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CircleSessionUiStatus.failure,
          message: 'تعذر إرسال طلب إضافة الطالب.',
        ),
      );
    }
  }
}
