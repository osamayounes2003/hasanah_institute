import '../../../../core/utils/iso_date_time.dart';
import '../../../../core/utils/syria_time.dart';
import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/circle_session_entities.dart';
import '../../domain/repositories/abstract_teacher_repository.dart';
import '../datasources/local_teacher_data_source.dart';

class SqliteTeacherRepository implements AbstractTeacherRepository {
  const SqliteTeacherRepository(this._localDataSource);

  final LocalTeacherDataSource _localDataSource;

  @override
  Future<Circle?> getCircleForTeacher(String teacherId) async => null;

  @override
  Future<List<MonthlyPlan>> listMonthlyPlans(String circleId) async =>
      const [];

  @override
  Future<void> saveMonthlyPlan(MonthlyPlan plan) async {}

  @override
  Future<void> deleteMonthlyPlan(String planId) async {}

  @override
  Future<Map<String, int>> studentPointsMap(String circleId) async => const {};

  @override
  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) async {}

  @override
  Future<void> updateSessionDetails({
    required String sessionId,
    required String lessonTitle,
    required int successRate,
    required String startedAt,
    String? endedAt,
  }) async {
    final rate = successRate.clamp(0, 100);
    final startDate = startedAt.length >= 10
        ? startedAt.substring(0, 10)
        : startedAt;
    await _localDataSource.updateSession(sessionId, {
      'lesson_title': lessonTitle.trim(),
      'success_rate': rate,
      'session_date': startDate,
      'started_at': startedAt,
      'ended_at': endedAt,
      'updated_at': IsoDateTime.encode(DateTime.now()),
    });
  }

  @override
  Future<List<SessionReport>> listSessionReports(String circleId) async =>
      const [];

  @override
  Future<void> submitStudentRequest(StudentJoinRequest request) async {}

  @override
  Future<List<StudentJoinRequest>> listMyStudentRequests({
    required String circleId,
    required String teacherId,
  }) async =>
      const [];

  @override
  Future<int> promoteDailyQuestionsToBank(String circleId) async => 0;

  @override
  Future<InstituteUser> addStudentToCircle({
    required String circleId,
    required String studentName,
  }) async {
    final now = DateTime.now().toUtc();
    return InstituteUser(
      id: 'student-${now.millisecondsSinceEpoch}',
      name: studentName.trim(),
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<InstituteUser>> fetchCircleStudents(String circleId) async {
    final rows = await _localDataSource.circleStudents(circleId);
    return rows.map(_userFromRow).toList();
  }

  @override
  Future<TeachingSession?> getOpenSession(String circleId) async {
    final row = await _localDataSource.openSession(circleId);
    return row == null ? null : _sessionFromRow(row);
  }

  @override
  Future<TeachingSession?> getSessionForDate({
    required String circleId,
    required String sessionDate,
  }) async {
    final row = await _localDataSource.sessionForDate(
      circleId: circleId,
      sessionDate: sessionDate,
    );
    return row == null ? null : _sessionFromRow(row);
  }

  @override
  Future<TeachingSession> startSession({
    required String circleId,
    required String teacherId,
  }) async {
    final existingOpen = await getOpenSession(circleId);
    if (existingOpen != null) return existingOpen;

    final syriaNow = SyriaTime.now();
    final sessionDate = SyriaTime.dateString(syriaNow);
    final timestamp = SyriaTime.dateTimeString(syriaNow);
    final session = TeachingSession(
      id: 'session-$circleId-${SyriaTime.idStamp(syriaNow)}',
      circleId: circleId,
      teacherId: teacherId,
      sessionDate: sessionDate,
      startedAt: timestamp,
      status: TeachingSessionStatus.open,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _localDataSource.insertSession({
      'id': session.id,
      'circle_id': session.circleId,
      'teacher_id': session.teacherId,
      'session_date': session.sessionDate,
      'started_at': session.startedAt,
      'ended_at': null,
      'status': session.status.name,
      'created_at': session.createdAt,
      'updated_at': session.updatedAt,
    });
    return session;
  }

  @override
  Future<TeachingSession> endSession(String sessionId) async {
    final row = await _localDataSource.sessionById(sessionId);
    if (row == null) throw StateError('الجلسة غير موجودة.');
    final now = SyriaTime.dateTimeString();
    await _localDataSource.updateSession(sessionId, {
      'status': TeachingSessionStatus.closed.name,
      'ended_at': now,
      'updated_at': now,
    });
    final updated = await _localDataSource.sessionById(sessionId);
    return _sessionFromRow(updated!);
  }

  @override
  Future<void> saveDailyAttendance({
    required TeachingSession session,
    required List<AttendanceRecord> records,
  }) async {
    if (!session.isOpen) {
      throw StateError('لا يمكن تسجيل الحضور بعد إنهاء الجلسة.');
    }
    final attendanceRows = <Map<String, Object?>>[];
    final pointRows = <Map<String, Object?>>[];
    for (final record in records) {
      attendanceRows.add({
        'id': record.id,
        'student_id': record.studentId,
        'circle_id': record.circleId,
        'session_id': session.id,
        'attendance_date': record.attendanceDate,
        'attendance_at': record.attendanceAt,
        'status': record.status.name,
        'created_at': record.createdAt,
        'updated_at': record.updatedAt,
      });
      if (record.status == AttendanceStatus.present ||
          record.status == AttendanceStatus.late) {
        pointRows.add({
          'id': 'point-attendance-${record.studentId}-${record.attendanceDate}',
          'student_id': record.studentId,
          'circle_id': record.circleId,
          'session_id': session.id,
          'points': 1,
          'reason': PointReason.attendance.name,
          'note': 'نقطة حضور',
          'awarded_at': record.attendanceAt,
          'created_at': record.createdAt,
        });
      }
    }
    await _localDataSource.saveAttendanceWithPoints(
      attendanceRows: attendanceRows,
      pointRows: pointRows,
    );
  }

  @override
  Future<void> awardPoints(PointEntry entry) {
    return _localDataSource.insertPoint({
      'id': entry.id,
      'student_id': entry.studentId,
      'circle_id': entry.circleId,
      'session_id': entry.sessionId,
      'points': entry.points,
      'reason': entry.reason.name,
      'note': entry.note,
      'awarded_at': entry.awardedAt,
      'created_at': entry.createdAt,
    });
  }

  @override
  Future<List<QaQuestion>> listQuestions(String circleId) async {
    final rows = await _localDataSource.questions(circleId);
    return rows.map(_questionFromRow).toList();
  }

  @override
  Future<void> saveQuestion(QaQuestion question) {
    return _localDataSource.upsertQuestion({
      'id': question.id,
      'circle_id': question.circleId,
      'question': question.question,
      'answer': question.answer,
      'category': question.category.name,
      'pool': question.pool.name,
      'asked_count': question.askedCount,
      'correct_count': question.correctCount,
      'points': question.points,
      'created_by': question.createdBy,
      'created_at': question.createdAt,
      'updated_at': question.updatedAt,
    });
  }

  @override
  Future<void> deleteQuestion(String questionId) {
    return _localDataSource.removeQuestion(questionId);
  }

  @override
  Future<QaQuestion?> pickRandomQuestion(
    String circleId, {
    QuestionCategory? category,
    QuestionPool pool = QuestionPool.bank,
  }) async {
    final questions = await listQuestions(circleId);
    final filtered = questions.where((q) {
      if (q.pool != pool) return false;
      if (category != null && q.category != category) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) return null;
    return filtered[DateTime.now().millisecond % filtered.length];
  }

  @override
  Future<List<HonorEntry>> getHonorBoard({
    required String circleId,
    required HonorPeriod period,
    String? openSessionId,
  }) async {
    if (period == HonorPeriod.daily) {
      final rows = await _localDataSource.honorBoardBySession(
        circleId: circleId,
        sessionId: openSessionId ?? '',
      );
      return [
        for (var index = 0; index < rows.length; index++)
          HonorEntry(
            studentId: rows[index]['student_id']! as String,
            studentName: rows[index]['student_name']! as String,
            totalPoints: (rows[index]['total_points'] as num).toInt(),
            rank: index + 1,
            isChampion:
                index == 0 &&
                (rows[index]['total_points'] as num).toInt() > 0,
          ),
      ];
    }

    final range = _periodRange(period);
    final rows = await _localDataSource.honorBoard(
      circleId: circleId,
      fromIso: range.$1,
      toIso: range.$2,
    );
    return [
      for (var index = 0; index < rows.length; index++)
        HonorEntry(
          studentId: rows[index]['student_id']! as String,
          studentName: rows[index]['student_name']! as String,
          totalPoints: (rows[index]['total_points'] as num).toInt(),
          rank: index + 1,
          isChampion: false,
        ),
    ];
  }

  (String, String) _periodRange(HonorPeriod period) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    switch (period) {
      case HonorPeriod.daily:
        final next = today.add(const Duration(days: 1));
        return (IsoDateTime.encode(today), IsoDateTime.encode(next));
      case HonorPeriod.weekly:
        final start = today.subtract(Duration(days: today.weekday % 7));
        final end = start.add(const Duration(days: 7));
        return (IsoDateTime.encode(start), IsoDateTime.encode(end));
      case HonorPeriod.monthly:
        final start = DateTime.utc(today.year, today.month, 1);
        final end = DateTime.utc(today.year, today.month + 1, 1);
        return (IsoDateTime.encode(start), IsoDateTime.encode(end));
    }
  }

  TeachingSession _sessionFromRow(Map<String, Object?> row) {
    return TeachingSession(
      id: row['id']! as String,
      circleId: row['circle_id']! as String,
      teacherId: row['teacher_id']! as String,
      sessionDate: row['session_date']! as String,
      startedAt: row['started_at']! as String,
      endedAt: row['ended_at'] as String?,
      status: TeachingSessionStatus.values.byName(row['status']! as String),
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
    );
  }

  QaQuestion _questionFromRow(Map<String, Object?> row) {
    return QaQuestion(
      id: row['id']! as String,
      circleId: row['circle_id']! as String,
      question: row['question']! as String,
      answer: row['answer']! as String,
      category: QuestionCategory.fromStorage(row['category'] as String?),
      pool: QuestionPool.fromStorage(row['pool'] as String?),
      askedCount: (row['asked_count'] as num?)?.toInt() ?? 0,
      correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
      points: (row['points'] as num?)?.toInt() ?? 0,
      createdBy: row['created_by']! as String,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
    );
  }

  InstituteUser _userFromRow(Map<String, Object?> row) {
    return InstituteUser(
      id: row['id']! as String,
      name: row['name']! as String,
      phone: row['phone'] as String?,
      password: row['password'] as String?,
      role: UserRole.values.byName(row['role']! as String),
      parentId: row['parent_id'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
      totalPoints: (row['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}
