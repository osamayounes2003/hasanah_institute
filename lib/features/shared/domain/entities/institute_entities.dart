enum UserRole { admin, teacher, student, parent }

enum AttendanceStatus { present, absent, late }

class InstituteUser {
  const InstituteUser({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.password,
    this.parentId,
    this.totalPoints = 0,
  });

  final String id;
  final String name;
  final UserRole role;
  final String? phone;
  final String? password;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalPoints;
}

class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.createdAt,
    required this.updatedAt,
    this.teacherName,
  });

  final String id;
  final String name;
  final String teacherId;
  final String? teacherName;
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
  });

  final String id;
  final String studentId;
  final DateTime evaluatedAt;
  final double newHifzScore;
  final double closeReviewScore;
  final double distantReviewScore;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
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
