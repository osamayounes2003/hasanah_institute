import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/cache/app_read_cache.dart';
import '../../../../core/firebase/firestore_paths.dart';
import '../../../../core/firebase/firestore_read.dart';
import '../../../../core/utils/iso_date_time.dart';
import '../../../../core/utils/syria_time.dart';
import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/circle_session_entities.dart';
import '../../domain/repositories/abstract_teacher_repository.dart';

class FirestoreTeacherRepository implements AbstractTeacherRepository {
  FirestoreTeacherRepository(this._firestore, {AppReadCache? cache})
    : _cache = cache ?? AppReadCache();

  final FirebaseFirestore _firestore;
  final AppReadCache _cache;

  @override
  Future<Circle?> getCircleForTeacher(String teacherId) async {
    final key = 'teacherCircle:$teacherId';
    final cached = _cache.get<Circle>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.circles)
          .where('teacher_id', isEqualTo: teacherId)
          .limit(1),
    );
    if (snap.docs.isEmpty) return null;
    final row = snap.docs.single.data();
    final circle = Circle(
      id: row['id'] as String,
      name: row['name'] as String,
      teacherId: row['teacher_id'] as String,
      teacherName: row['teacher_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
    _cache.set(key, circle);
    return circle;
  }

  @override
  Future<List<InstituteUser>> fetchCircleStudents(String circleId) async {
    final key = 'students:$circleId';
    final cached = _cache.get<List<InstituteUser>>(key);
    if (cached != null) return cached;
    final links = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.circleStudents)
          .where('circle_id', isEqualTo: circleId),
    );
    final ids = [
      for (final link in links.docs) link.data()['student_id'] as String,
    ];
    final users = await _usersByIds(ids);
    final students = [
      for (final user in users)
        if (user.role == UserRole.student) user,
    ]..sort((a, b) => a.name.compareTo(b.name));
    _cache.set(key, students);
    return students;
  }

  @override
  Future<TeachingSession?> getOpenSession(String circleId) async {
    final sessions = await _sessions(circleId);
    for (final session in sessions) {
      if (session.isOpen) return session;
    }
    return null;
  }

  @override
  Future<TeachingSession?> getSessionForDate({
    required String circleId,
    required String sessionDate,
  }) async {
    final sessions = await _sessions(circleId);
    for (final session in sessions) {
      if (session.sessionDate == sessionDate) return session;
    }
    return null;
  }

  @override
  Future<TeachingSession> startSession({
    required String circleId,
    required String teacherId,
  }) async {
    final existingOpen = await getOpenSession(circleId);
    if (existingOpen != null) return existingOpen;

    // Multiple sessions per day are allowed; stamp uses Syria wall-clock.
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
      lessonTitle: '',
      successRate: 0,
    );
    _cache.invalidate('sessions:$circleId');
    _cache.invalidatePrefix('reports:$circleId');
    _cache.invalidatePrefix('honor:$circleId');
    await _firestore
        .collection(FirestorePaths.teachingSessions)
        .doc(session.id)
        .set({
          'id': session.id,
          'circle_id': session.circleId,
          'teacher_id': session.teacherId,
          'session_date': session.sessionDate,
          'started_at': session.startedAt,
          'ended_at': null,
          'status': session.status.name,
          'lesson_title': '',
          'success_rate': 0,
          'created_at': session.createdAt,
          'updated_at': session.updatedAt,
          'timezone': 'Asia/Damascus',
        });
    return session;
  }

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
    _cache.invalidatePrefix('sessions:');
    _cache.invalidatePrefix('reports:');
    await _firestore.collection(FirestorePaths.teachingSessions).doc(sessionId).set(
      {
        'lesson_title': lessonTitle.trim(),
        'success_rate': rate,
        'session_date': startDate,
        'started_at': startedAt,
        'ended_at': endedAt,
        'updated_at': IsoDateTime.encode(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<List<SessionReport>> listSessionReports(String circleId) async {
    final key = 'reports:$circleId';
    final cached = _cache.get<List<SessionReport>>(key);
    if (cached != null) return cached;

    final fetched = await Future.wait([
      _sessions(circleId),
      _attendanceMaps(circleId),
      _pointMaps(circleId),
    ]);
    final sessions = fetched[0] as List<TeachingSession>;
    final attendance = fetched[1] as List<Map<String, dynamic>>;
    final points = fetched[2] as List<Map<String, dynamic>>;

    final nameIds = <String>{
      for (final row in attendance) row['student_id'] as String,
      for (final row in points) row['student_id'] as String,
    };
    final users = {
      for (final user in await _usersByIds(nameIds)) user.id: user,
    };
    String nameOf(String studentId) => users[studentId]?.name ?? studentId;

    final reports = <SessionReport>[];
    for (final session in sessions) {
      final attendees = <SessionAttendee>[];
      for (final data in attendance) {
        if (data['session_id'] != session.id) continue;
        final studentId = data['student_id'] as String;
        final statusName = data['status'] as String? ?? 'absent';
        attendees.add(
          SessionAttendee(
            studentId: studentId,
            studentName: nameOf(studentId),
            status: AttendanceStatus.values.byName(statusName),
          ),
        );
      }
      attendees.sort((a, b) => a.studentName.compareTo(b.studentName));

      final awards = <SessionPointAward>[];
      for (final data in points) {
        if (data['session_id'] != session.id) continue;
        final studentId = data['student_id'] as String;
        final reasonName = data['reason'] as String? ?? 'award';
        awards.add(
          SessionPointAward(
            studentId: studentId,
            studentName: nameOf(studentId),
            points: (data['points'] as num).toInt(),
            reason: PointReason.values.byName(reasonName),
            note: data['note'] as String?,
          ),
        );
      }
      awards.sort((a, b) => b.points.compareTo(a.points));

      reports.add(
        SessionReport(
          session: session,
          attendees: attendees,
          pointAwards: awards,
        ),
      );
    }
    _cache.set(key, reports);
    return reports;
  }

  @override
  Future<TeachingSession> endSession(String sessionId) async {
    final ref = _firestore
        .collection(FirestorePaths.teachingSessions)
        .doc(sessionId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('الجلسة غير موجودة.');
    final now = SyriaTime.dateTimeString();
    _cache.invalidatePrefix('sessions:');
    _cache.invalidatePrefix('reports:');
    _cache.invalidatePrefix('honor:');
    await ref.update({
      'status': TeachingSessionStatus.closed.name,
      'ended_at': now,
      'updated_at': now,
    });
    final updated = await ref.get();
    return _sessionFromMap(updated.data()!);
  }

  @override
  Future<void> saveDailyAttendance({
    required TeachingSession session,
    required List<AttendanceRecord> records,
  }) async {
    if (!session.isOpen) {
      throw StateError('لا يمكن تسجيل الحضور بعد إنهاء الجلسة.');
    }
    final batch = _firestore.batch();
    for (final record in records) {
      final attendanceRef = _firestore
          .collection(FirestorePaths.attendance)
          .doc(record.id);
      batch.set(attendanceRef, {
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
        final pointId =
            'point-attendance-${record.studentId}-${record.attendanceDate}';
        batch.set(
          _firestore.collection(FirestorePaths.pointLedger).doc(pointId),
          {
            'id': pointId,
            'student_id': record.studentId,
            'circle_id': record.circleId,
            'session_id': session.id,
            'points': 1,
            'reason': PointReason.attendance.name,
            'note': 'نقطة حضور',
            'awarded_at': record.attendanceAt,
            'created_at': record.createdAt,
          },
        );
      }
    }
    _cache.invalidate('points:${session.circleId}');
    _cache.invalidate('attendance:${session.circleId}');
    _cache.invalidate('reports:${session.circleId}');
    _cache.invalidatePrefix('honor:${session.circleId}');
    await batch.commit();
  }

  @override
  Future<void> awardPoints(PointEntry entry) {
    _cache.invalidate('points:${entry.circleId}');
    _cache.invalidate('reports:${entry.circleId}');
    _cache.invalidatePrefix('honor:${entry.circleId}');
    return _firestore.collection(FirestorePaths.pointLedger).doc(entry.id).set({
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
    final snap = await _firestore
        .collection(FirestorePaths.qaQuestions)
        .where('circle_id', isEqualTo: circleId)
        .get();
    final questions = snap.docs
        .map((doc) => _questionFromMap(doc.data()))
        .toList();
    questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache.set('questions:$circleId', questions);
    return questions;
  }

  @override
  Future<void> saveQuestion(QaQuestion question) {
    _upsertCachedQuestion(question);
    return _firestore
        .collection(FirestorePaths.qaQuestions)
        .doc(question.id)
        .set({
          'id': question.id,
          'circle_id': question.circleId,
          'question': question.question,
          'answer': question.answer,
          'category': question.category.name,
          'category_label': question.category.label,
          'pool': question.pool.name,
          'asked_count': question.askedCount,
          'correct_count': question.correctCount,
          'points': question.points,
          'shown_session_id': question.shownSessionId,
          'created_by': question.createdBy,
          'created_at': question.createdAt,
          'updated_at': question.updatedAt,
        });
  }

  @override
  Future<void> deleteQuestion(String questionId) {
    _cache.invalidatePrefix('questions:');
    return _firestore
        .collection(FirestorePaths.qaQuestions)
        .doc(questionId)
        .delete();
  }

  @override
  Future<QaQuestion?> pickRandomQuestion(
    String circleId, {
    QuestionCategory? category,
    QuestionPool pool = QuestionPool.bank,
    String? sessionId,
  }) async {
    final questions = await listQuestions(circleId);
    final filtered = questions.where((q) {
      if (q.pool != pool) return false;
      if (category != null && q.category != category) return false;
      if (sessionId != null && q.wasShownIn(sessionId)) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) return null;
    final picked = filtered[Random().nextInt(filtered.length)];
    if (sessionId == null || sessionId.isEmpty) return picked;
    final marked = picked.copyWith(
      shownSessionId: sessionId,
      askedCount: picked.askedCount + 1,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    unawaited(saveQuestion(marked));
    return marked;
  }

  @override
  Future<int> promoteDailyQuestionsToBank(String circleId) async {
    final daily = (await listQuestions(circleId))
        .where((q) => q.pool == QuestionPool.daily)
        .toList();
    if (daily.isEmpty) return 0;
    _cache.invalidate('questions:$circleId');
    final now = DateTime.now().toUtc().toIso8601String();
    final batch = _firestore.batch();
    for (final question in daily) {
      batch.set(
        _firestore.collection(FirestorePaths.qaQuestions).doc(question.id),
        {
          'pool': QuestionPool.bank.name,
          'asked_count': 0,
          'correct_count': 0,
          'points': 0,
          'category': question.category.name,
          'category_label': question.category.label,
          'updated_at': now,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return daily.length;
  }

  @override
  Future<InstituteUser> addStudentToCircle({
    required String circleId,
    required String studentName,
  }) async {
    final now = DateTime.now().toUtc();
    final studentId = 'student-${now.millisecondsSinceEpoch}';
    final createdAt = now.toIso8601String();
    final batch = _firestore.batch();
    batch.set(_firestore.collection(FirestorePaths.users).doc(studentId), {
      'id': studentId,
      'name': studentName.trim(),
      'role': UserRole.student.name,
      'password': null,
      'created_at': createdAt,
      'updated_at': createdAt,
      'total_points': 0,
    });
    batch.set(
      _firestore
          .collection(FirestorePaths.circleStudents)
          .doc('${circleId}_$studentId'),
      {
        'circle_id': circleId,
        'student_id': studentId,
        'created_at': createdAt,
      },
    );
    _cache.invalidate('students:$circleId');
    _cache.invalidatePrefix('admin:');
    await batch.commit();
    final student = InstituteUser(
      id: studentId,
      name: studentName.trim(),
      role: UserRole.student,
      createdAt: now,
      updatedAt: now,
      totalPoints: 0,
    );
    _cache.set('user:$studentId', student);
    return student;
  }

  @override
  Future<List<HonorEntry>> getHonorBoard({
    required String circleId,
    required HonorPeriod period,
    String? openSessionId,
  }) async {
    final key = 'honor:$circleId:${period.name}:${openSessionId ?? ''}';
    final cached = _cache.get<List<HonorEntry>>(key);
    if (cached != null) return cached;

    final students = await fetchCircleStudents(circleId);
    final pointRows = await _pointMaps(circleId);

    final totals = <String, int>{for (final student in students) student.id: 0};

    if (period == HonorPeriod.daily) {
      // Daily board = points of the currently open session only.
      if (openSessionId == null || openSessionId.isEmpty) {
        final empty = [
          for (var index = 0; index < students.length; index++)
            HonorEntry(
              studentId: students[index].id,
              studentName: students[index].name,
              totalPoints: 0,
              rank: index + 1,
              isChampion: false,
            ),
        ];
        _cache.set(key, empty);
        return empty;
      }
      for (final data in pointRows) {
        if (data['session_id'] != openSessionId) continue;
        final studentId = data['student_id'] as String;
        final points = (data['points'] as num).toInt();
        totals[studentId] = (totals[studentId] ?? 0) + points;
      }
    } else {
      // Weekly / monthly = cumulative points from all sessions in the period.
      final bounds = _periodBounds(period);
      for (final data in pointRows) {
        final awardedAt = data['awarded_at'] as String? ?? '';
        if (!_awardedInSyriaPeriod(awardedAt, bounds.$1, bounds.$2)) {
          continue;
        }
        final studentId = data['student_id'] as String;
        final points = (data['points'] as num).toInt();
        totals[studentId] = (totals[studentId] ?? 0) + points;
      }
    }

    final ranked =
        [
          for (final student in students)
            (student: student, total: totals[student.id] ?? 0),
        ]..sort((a, b) {
          final byPoints = b.total.compareTo(a.total);
          if (byPoints != 0) return byPoints;
          return a.student.name.compareTo(b.student.name);
        });

    final honor = [
      for (var index = 0; index < ranked.length; index++)
        HonorEntry(
          studentId: ranked[index].student.id,
          studentName: ranked[index].student.name,
          totalPoints: ranked[index].total,
          rank: index + 1,
          isChampion:
              period == HonorPeriod.daily &&
              index == 0 &&
              ranked[index].total > 0,
        ),
    ];
    _cache.set(key, honor);
    return honor;
  }

  @override
  Future<List<MonthlyPlan>> listMonthlyPlans(String circleId) async {
    final key = 'plans:$circleId';
    final cached = _cache.get<List<MonthlyPlan>>(key);
    if (cached != null) return cached;
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await getQueryPreferCache(
        _firestore
            .collection(FirestorePaths.monthlyPlans)
            .where('circle_id', isEqualTo: circleId),
      );
    } catch (_) {
      snap = await getQueryPreferCache(
        _firestore.collection(FirestorePaths.monthlyPlans),
      );
    }
    final plans = snap.docs
        .map((d) => d.data())
        .where((row) => row['circle_id'] == circleId)
        .map(_planFromMap)
        .toList();
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache.set(key, plans);
    return plans;
  }

  @override
  Future<void> saveMonthlyPlan(MonthlyPlan plan) async {
    _cache.invalidate('plans:${plan.circleId}');
    await _firestore.collection(FirestorePaths.monthlyPlans).doc(plan.id).set({
      'id': plan.id,
      'circle_id': plan.circleId,
      'title': plan.title,
      'planned_lessons_count': plan.plannedLessonsCount,
      'lessons': [
        for (final lesson in plan.lessons)
          {'id': lesson.id, 'title': lesson.title, 'date': lesson.date},
      ],
      'created_by': plan.createdBy,
      'created_at': plan.createdAt,
      'updated_at': plan.updatedAt,
    });
  }

  @override
  Future<void> deleteMonthlyPlan(String planId) {
    _cache.invalidatePrefix('plans:');
    return _firestore.collection(FirestorePaths.monthlyPlans).doc(planId).delete();
  }

  @override
  Future<Map<String, int>> studentPointsMap(String circleId) async {
    final rows = await _pointMaps(circleId);
    final totals = <String, int>{};
    for (final data in rows) {
      final studentId = data['student_id'] as String;
      totals[studentId] =
          (totals[studentId] ?? 0) + (data['points'] as num).toInt();
    }
    return totals;
  }

  @override
  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) {
    _cache.invalidate('students:$circleId');
    _cache.invalidatePrefix('honor:$circleId');
    _cache.invalidatePrefix('admin:');
    return _firestore
        .collection(FirestorePaths.circleStudents)
        .doc('${circleId}_$studentId')
        .delete();
  }

  @override
  Future<void> submitStudentRequest(StudentJoinRequest request) {
    return _firestore
        .collection(FirestorePaths.studentRequests)
        .doc(request.id)
        .set({
          'id': request.id,
          'student_name': request.studentName,
          'circle_id': request.circleId,
          'circle_name': request.circleName,
          'teacher_id': request.teacherId,
          'teacher_name': request.teacherName,
          'status': request.status.name,
          'created_at': request.createdAt,
          'updated_at': request.updatedAt,
        });
  }

  @override
  Future<List<StudentJoinRequest>> listMyStudentRequests({
    required String circleId,
    required String teacherId,
  }) async {
    final snap = await _firestore
        .collection(FirestorePaths.studentRequests)
        .where('circle_id', isEqualTo: circleId)
        .get();
    final list = snap.docs
        .map((d) => _requestFromMap(d.data()))
        .where((r) => r.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _upsertCachedQuestion(QaQuestion question) {
    final key = 'questions:${question.circleId}';
    final current = _cache.get<List<QaQuestion>>(key);
    if (current == null) return;
    final next = <QaQuestion>[
      for (final item in current)
        if (item.id == question.id) question else item,
    ];
    if (!next.any((item) => item.id == question.id)) {
      next.insert(0, question);
    }
    _cache.set(key, next);
  }

  Future<List<InstituteUser>> _usersByIds(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    final found = <String, InstituteUser>{};
    final missing = <String>[];
    for (final id in unique) {
      final hit = _cache.get<InstituteUser>('user:$id');
      if (hit != null) {
        found[id] = hit;
      } else {
        missing.add(id);
      }
    }
    if (missing.isNotEmpty) {
      final snaps = await Future.wait([
        for (final id in missing)
          _firestore.collection(FirestorePaths.users).doc(id).get(),
      ]);
      for (final snap in snaps) {
        final data = snap.data();
        if (data == null) continue;
        final user = _userFromMap(data);
        _cache.set('user:${user.id}', user);
        found[user.id] = user;
      }
    }
    return [for (final id in unique) if (found[id] != null) found[id]!];
  }

  Future<List<TeachingSession>> _sessions(String circleId) async {
    final key = 'sessions:$circleId';
    final cached = _cache.get<List<TeachingSession>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.teachingSessions)
          .where('circle_id', isEqualTo: circleId),
    );
    final sessions = snap.docs.map((d) => _sessionFromMap(d.data())).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _cache.set(key, sessions);
    return sessions;
  }

  Future<List<Map<String, dynamic>>> _pointMaps(String circleId) async {
    final key = 'points:$circleId';
    final cached = _cache.get<List<Map<String, dynamic>>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.pointLedger)
          .where('circle_id', isEqualTo: circleId),
    );
    final rows = [for (final doc in snap.docs) doc.data()];
    _cache.set(key, rows);
    return rows;
  }

  Future<List<Map<String, dynamic>>> _attendanceMaps(String circleId) async {
    final key = 'attendance:$circleId';
    final cached = _cache.get<List<Map<String, dynamic>>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.attendance)
          .where('circle_id', isEqualTo: circleId),
    );
    final rows = [for (final doc in snap.docs) doc.data()];
    _cache.set(key, rows);
    return rows;
  }

  StudentJoinRequest _requestFromMap(Map<String, dynamic> row) {
    return StudentJoinRequest(
      id: row['id'] as String? ?? '',
      studentName: row['student_name'] as String? ?? '',
      circleId: row['circle_id'] as String? ?? '',
      circleName: row['circle_name'] as String?,
      teacherId: row['teacher_id'] as String? ?? '',
      teacherName: row['teacher_name'] as String?,
      status: StudentRequestStatus.values.byName(
        row['status'] as String? ?? 'pending',
      ),
      createdAt: row['created_at'] as String? ?? '',
      updatedAt: row['updated_at'] as String? ?? '',
    );
  }

  MonthlyPlan _planFromMap(Map<String, dynamic> row) {
    final rawLessons = (row['lessons'] as List?) ?? const [];
    return MonthlyPlan(
      id: row['id'] as String? ?? '',
      circleId: row['circle_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      plannedLessonsCount: (row['planned_lessons_count'] as num?)?.toInt() ?? 0,
      lessons: [
        for (final item in rawLessons)
          if (item is Map)
            PlanLessonItem(
              id: '${item['id'] ?? ''}',
              title: '${item['title'] ?? ''}',
              date: '${item['date'] ?? ''}',
            ),
      ],
      createdBy: row['created_by'] as String? ?? '',
      createdAt: row['created_at'] as String? ?? '',
      updatedAt: row['updated_at'] as String? ?? '',
    );
  }

  /// Syria-local day bounds: `[start, endExclusive)`.
  (DateTime, DateTime) _periodBounds(HonorPeriod period) {
    final syria = SyriaTime.now();
    final today = DateTime(syria.year, syria.month, syria.day);
    switch (period) {
      case HonorPeriod.daily:
        return (today, today.add(const Duration(days: 1)));
      case HonorPeriod.weekly:
        final start = today.subtract(Duration(days: today.weekday % 7));
        return (start, start.add(const Duration(days: 7)));
      case HonorPeriod.monthly:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return (start, end);
    }
  }

  bool _awardedInSyriaPeriod(
    String awardedAt,
    DateTime start,
    DateTime endExclusive,
  ) {
    if (awardedAt.isEmpty) return false;
    try {
      final parsed = DateTime.parse(awardedAt);
      // Treat naive timestamps as already Syria wall-clock; UTC as convertible.
      final syria = parsed.isUtc
          ? parsed.add(SyriaTime.offset)
          : parsed;
      final day = DateTime(syria.year, syria.month, syria.day);
      return !day.isBefore(start) && day.isBefore(endExclusive);
    } catch (_) {
      return false;
    }
  }

  TeachingSession _sessionFromMap(Map<String, dynamic> row) {
    return TeachingSession(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      teacherId: row['teacher_id'] as String,
      sessionDate: row['session_date'] as String,
      startedAt: row['started_at'] as String,
      endedAt: row['ended_at'] as String?,
      status: TeachingSessionStatus.values.byName(row['status'] as String),
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
      lessonTitle: row['lesson_title'] as String?,
      successRate: (row['success_rate'] as num?)?.toInt() ?? 0,
    );
  }

  QaQuestion _questionFromMap(Map<String, dynamic> row) {
    return QaQuestion(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      question: row['question'] as String,
      answer: row['answer'] as String,
      category: QuestionCategory.fromStorage(
        (row['category'] as String?) ?? (row['category_label'] as String?),
      ),
      pool: QuestionPool.fromStorage(row['pool'] as String?),
      askedCount: (row['asked_count'] as num?)?.toInt() ?? 0,
      correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
      points: (row['points'] as num?)?.toInt() ?? 0,
      shownSessionId: row['shown_session_id'] as String? ?? '',
      createdBy: row['created_by'] as String,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    );
  }

  InstituteUser _userFromMap(Map<String, dynamic> row) {
    return InstituteUser(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      password: row['password'] as String?,
      role: UserRole.values.byName(row['role'] as String),
      parentId: row['parent_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      totalPoints: (row['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}
