import '../../../shared/domain/entities/institute_entities.dart'
    show AttendanceStatus;

enum TeachingSessionStatus { open, closed }

enum PointReason { attendance, award, qa }

enum HonorPeriod { daily, weekly, monthly }

class TeachingSession {
  const TeachingSession({
    required this.id,
    required this.circleId,
    required this.teacherId,
    required this.sessionDate,
    required this.startedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
    this.lessonTitle,
    this.successRate = 0,
  });

  final String id;
  final String circleId;
  final String teacherId;
  final String sessionDate;
  final String startedAt;
  final String? endedAt;
  final TeachingSessionStatus status;
  final String createdAt;
  final String updatedAt;
  final String? lessonTitle;
  final int successRate;

  bool get isOpen => status == TeachingSessionStatus.open;
}

class SessionAttendee {
  const SessionAttendee({
    required this.studentId,
    required this.studentName,
    required this.status,
  });

  final String studentId;
  final String studentName;
  final AttendanceStatus status;
}

class SessionPointAward {
  const SessionPointAward({
    required this.studentId,
    required this.studentName,
    required this.points,
    required this.reason,
    this.note,
  });

  final String studentId;
  final String studentName;
  final int points;
  final PointReason reason;
  final String? note;
}

class SessionReport {
  const SessionReport({
    required this.session,
    required this.attendees,
    required this.pointAwards,
  });

  final TeachingSession session;
  final List<SessionAttendee> attendees;
  final List<SessionPointAward> pointAwards;

  List<SessionAttendee> get presentStudents =>
      attendees.where((a) => a.status == AttendanceStatus.present).toList();
}

enum StudentRequestStatus { pending, approved, rejected }

class StudentJoinRequest {
  const StudentJoinRequest({
    required this.id,
    required this.studentName,
    required this.circleId,
    required this.teacherId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.circleName,
    this.teacherName,
  });

  final String id;
  final String studentName;
  final String circleId;
  final String? circleName;
  final String teacherId;
  final String? teacherName;
  final StudentRequestStatus status;
  final String createdAt;
  final String updatedAt;
}

class PointEntry {
  const PointEntry({
    required this.id,
    required this.studentId,
    required this.circleId,
    required this.points,
    required this.reason,
    required this.awardedAt,
    required this.createdAt,
    this.sessionId,
    this.note,
  });

  final String id;
  final String studentId;
  final String circleId;
  final String? sessionId;
  final int points;
  final PointReason reason;
  final String? note;
  final String awardedAt;
  final String createdAt;
}

enum QuestionCategory {
  aqeedah('العقيدة'),
  fiqh('الفقه'),
  seerah('السيرة'),
  akhlaq('الأخلاق'),
  quran('القرآن والتفسير والتجويد');

  const QuestionCategory(this.label);
  final String label;

  static QuestionCategory fromLabel(String label) {
    for (final value in QuestionCategory.values) {
      if (value.label == label || value.name == label) return value;
    }
    return QuestionCategory.aqeedah;
  }

  static QuestionCategory fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return QuestionCategory.aqeedah;
    for (final value in QuestionCategory.values) {
      if (value.name == raw || value.label == raw) return value;
    }
    return QuestionCategory.aqeedah;
  }
}

enum QuestionPool {
  daily,
  bank;

  static QuestionPool fromStorage(String? raw) {
    if (raw == QuestionPool.daily.name) return QuestionPool.daily;
    return QuestionPool.bank;
  }
}

class QaQuestion {
  const QaQuestion({
    required this.id,
    required this.circleId,
    required this.question,
    required this.answer,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.pool = QuestionPool.bank,
    this.askedCount = 0,
    this.correctCount = 0,
    this.points = 0,
    this.shownSessionId = '',
  });

  final String id;
  final String circleId;
  final String question;
  final String answer;
  final QuestionCategory category;
  final QuestionPool pool;
  final int askedCount;
  final int correctCount;
  final int points;
  /// Session id/flag: when it matches the open session, the question
  /// already appeared on the wheel in that session.
  final String shownSessionId;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  bool wasShownIn(String sessionId) =>
      sessionId.isNotEmpty && shownSessionId == sessionId;

  QaQuestion copyWith({
    String? id,
    String? circleId,
    String? question,
    String? answer,
    QuestionCategory? category,
    QuestionPool? pool,
    int? askedCount,
    int? correctCount,
    int? points,
    String? shownSessionId,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return QaQuestion(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      pool: pool ?? this.pool,
      askedCount: askedCount ?? this.askedCount,
      correctCount: correctCount ?? this.correctCount,
      points: points ?? this.points,
      shownSessionId: shownSessionId ?? this.shownSessionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HonorEntry {
  const HonorEntry({
    required this.studentId,
    required this.studentName,
    required this.totalPoints,
    required this.rank,
    this.isChampion = false,
  });

  final String studentId;
  final String studentName;
  final int totalPoints;
  final int rank;
  final bool isChampion;
}

class PlanLessonItem {
  const PlanLessonItem({
    required this.id,
    required this.title,
    required this.date,
  });

  final String id;
  final String title;
  final String date;
}

class MonthlyPlan {
  const MonthlyPlan({
    required this.id,
    required this.circleId,
    required this.title,
    required this.plannedLessonsCount,
    required this.lessons,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String circleId;
  final String title;
  final int plannedLessonsCount;
  final List<PlanLessonItem> lessons;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
}
