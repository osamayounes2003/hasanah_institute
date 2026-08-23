import 'package:sqflite/sqflite.dart';

import '../utils/iso_date_time.dart';
import 'database_schema.dart';

abstract final class DatabaseSeeder {
  static Future<void> seedRbac(DatabaseExecutor executor) async {
    final createdAt = IsoDateTime.encode(DateTime.now());
    const permissions = <Map<String, String>>[
      {'id': 'manage_users', 'description': 'إدارة المستخدمين'},
      {'id': 'manage_circles', 'description': 'إدارة الحلقات'},
      {'id': 'run_session', 'description': 'بدء وإنهاء جلسة الحلقة'},
      {'id': 'edit_attendance', 'description': 'تسجيل حضور الحلقة'},
      {'id': 'award_points', 'description': 'إسناد نقاط للطلاب'},
      {'id': 'manage_questions', 'description': 'إدارة بنك الأسئلة'},
      {'id': 'view_honor_board', 'description': 'عرض لوحة الشرف'},
      {'id': 'export_reports', 'description': 'تصدير التقارير'},
    ];
    const rolePermissionCodes = <String, List<String>>{
      'admin': [
        'manage_users',
        'manage_circles',
        'run_session',
        'edit_attendance',
        'award_points',
        'manage_questions',
        'view_honor_board',
        'export_reports',
      ],
      'teacher': [
        'run_session',
        'edit_attendance',
        'award_points',
        'manage_questions',
        'view_honor_board',
      ],
    };

    for (final permission in permissions) {
      await executor.insert(DatabaseSchema.permissions, {
        ...permission,
        'code': permission['id'],
        'created_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final entry in rolePermissionCodes.entries) {
      for (final permissionId in entry.value) {
        await executor.insert(
          DatabaseSchema.rolePermissions,
          {'role': entry.key, 'permission_id': permissionId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Deterministic records used to demonstrate the offline MVP locally.
  static Future<void> seedDemoData(DatabaseExecutor executor) async {
    const createdAt = '2026-07-01T08:00:00.000Z';
    const users = [
      {'id': 'demo-admin', 'name': 'مدير المعهد', 'role': 'admin'},
      {'id': 'demo-teacher', 'name': 'الشيخ أحمد', 'role': 'teacher'},
      {'id': 'demo-parent', 'name': 'ولي أمر محمد', 'role': 'parent'},
      {
        'id': 'demo-student-1',
        'name': 'محمد علي',
        'role': 'student',
        'parent_id': 'demo-parent',
      },
      {'id': 'demo-student-2', 'name': 'فاطمة حسن', 'role': 'student'},
      {'id': 'demo-student-3', 'name': 'يوسف عمر', 'role': 'student'},
    ];
    for (final user in users) {
      await executor.insert(DatabaseSchema.users, {
        ...user,
        'created_at': createdAt,
        'updated_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await executor.insert(DatabaseSchema.circles, {
      'id': 'demo-circle-1',
      'name': 'حلقة الفجر',
      'teacher_id': 'demo-teacher',
      'created_at': createdAt,
      'updated_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    for (final studentId in [
      'demo-student-1',
      'demo-student-2',
      'demo-student-3',
    ]) {
      await executor.insert(DatabaseSchema.circleStudents, {
        'circle_id': 'demo-circle-1',
        'student_id': studentId,
        'created_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    const questions = [
      ('demo-q1', 'ما أول سورة في المصحف؟', 'سورة الفاتحة'),
      ('demo-q2', 'كم عدد أجزاء القرآن؟', 'ثلاثون جزءاً'),
      ('demo-q3', 'ما السورة التي تسمى قلب القرآن؟', 'سورة يس'),
    ];
    for (final question in questions) {
      await executor.insert(DatabaseSchema.qaQuestions, {
        'id': question.$1,
        'circle_id': 'demo-circle-1',
        'question': question.$2,
        'answer': question.$3,
        'created_by': 'demo-teacher',
        'created_at': createdAt,
        'updated_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final today = IsoDateTime.encode(DateTime.now()).substring(0, 10);
    await executor.insert(DatabaseSchema.pointLedger, {
      'id': 'demo-points-1',
      'student_id': 'demo-student-2',
      'circle_id': 'demo-circle-1',
      'points': 5,
      'reason': 'award',
      'note': 'نقاط تجريبية',
      'awarded_at': '${today}T08:00:00.000Z',
      'created_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await executor.insert(DatabaseSchema.pointLedger, {
      'id': 'demo-points-2',
      'student_id': 'demo-student-1',
      'circle_id': 'demo-circle-1',
      'points': 3,
      'reason': 'qa',
      'note': 'إجابة صحيحة',
      'awarded_at': '${today}T08:10:00.000Z',
      'created_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await executor.insert(DatabaseSchema.pointLedger, {
      'id': 'demo-points-3',
      'student_id': 'demo-student-3',
      'circle_id': 'demo-circle-1',
      'points': 1,
      'reason': 'attendance',
      'note': 'حضور',
      'awarded_at': '${today}T08:05:00.000Z',
      'created_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await executor.insert(DatabaseSchema.rewardStore, {
      'id': 'demo-reward-book',
      'name': 'كتاب قصص الأنبياء',
      'description': 'مكافأة تشجيعية للطالب.',
      'token_cost': 25,
      'available_quantity': 5,
      'created_at': createdAt,
      'updated_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
