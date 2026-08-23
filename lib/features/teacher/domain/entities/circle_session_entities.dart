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
  });

  final String id;
  final String circleId;
  final String question;
  final String answer;
  final QuestionCategory category;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
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
