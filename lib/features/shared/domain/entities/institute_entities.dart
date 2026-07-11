enum UserRole { admin, teacher, student, parent }

enum AttendanceStatus { present, absent, late }

class InstituteUser {
  const InstituteUser({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  final String id;
  final String name;
  final UserRole role;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String teacherId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.circleId,
    required this.attendanceAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String circleId;
  final DateTime attendanceAt;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Evaluation {
  const Evaluation({
    required this.id,
    required this.studentId,
    required this.evaluatedAt,
    required this.newHifzScore,
    required this.closeReviewScore,
    required this.distantReviewScore,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  }) : assert(newHifzScore >= 0 && newHifzScore <= 10),
       assert(closeReviewScore >= 0 && closeReviewScore <= 10),
       assert(distantReviewScore >= 0 && distantReviewScore <= 10);

  final String id;
  final String studentId;
  final DateTime evaluatedAt;
  final double newHifzScore;
  final double closeReviewScore;
  final double distantReviewScore;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get averageScore =>
      (newHifzScore + closeReviewScore + distantReviewScore) / 3;
}

class Permission {
  const Permission({
    required this.id,
    required this.code,
    required this.description,
  });

  final String id;
  final String code;
  final String description;
}
