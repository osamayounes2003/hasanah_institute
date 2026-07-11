import 'package:sqflite/sqflite.dart';

import '../utils/iso_date_time.dart';
import 'database_schema.dart';

abstract final class DatabaseSeeder {
  static Future<void> seedRbac(DatabaseExecutor executor) async {
    final createdAt = IsoDateTime.encode(DateTime.now());
    const permissions = <Map<String, String>>[
      {'id': 'manage_users', 'description': 'Manage institute users'},
      {'id': 'manage_circles', 'description': 'Manage Quran circles'},
      {'id': 'edit_attendance', 'description': 'Record circle attendance'},
      {'id': 'evaluate_students', 'description': 'Record student evaluations'},
      {'id': 'view_student_progress', 'description': 'View student progress'},
      {'id': 'export_reports', 'description': 'Export local institute reports'},
    ];
    const rolePermissionCodes = <String, List<String>>{
      'admin': [
        'manage_users',
        'manage_circles',
        'edit_attendance',
        'evaluate_students',
        'view_student_progress',
        'export_reports',
      ],
      'teacher': [
        'edit_attendance',
        'evaluate_students',
        'view_student_progress',
      ],
      'student': ['view_student_progress'],
      'parent': ['view_student_progress'],
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
      {'id': 'demo-teacher', 'name': 'الأستاذ أحمد', 'role': 'teacher'},
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

    const evaluationScores = <String, List<double>>{
      // The latest four scores are 6, while the earlier four are 10.
      // This intentionally produces a red intervention alert.
      'demo-student-1': [10, 10, 10, 10, 6, 6, 6, 6],
      'demo-student-2': [8, 8, 9, 8, 9, 8],
      'demo-student-3': [7, 8, 7, 8, 7, 8],
    };
    for (final entry in evaluationScores.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final score = entry.value[index];
        final day = (index + 1).toString().padLeft(2, '0');
        await executor.insert(DatabaseSchema.evaluations, {
          'id': 'demo-evaluation-${entry.key}-$index',
          'student_id': entry.key,
          'circle_id': 'demo-circle-1',
          'evaluated_at': '2026-07-${day}T08:00:00.000Z',
          'new_hifz_score': score,
          'close_review_score': score,
          'distant_review_score': score,
          'notes': entry.key == 'demo-student-1' && index >= 4
              ? 'يحتاج متابعة في المراجعة.'
              : 'تقييم تجريبي.',
          'created_at': createdAt,
          'updated_at': createdAt,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    for (final studentId in evaluationScores.keys) {
      await executor.insert(DatabaseSchema.attendance, {
        'id': 'demo-attendance-$studentId',
        'student_id': studentId,
        'circle_id': 'demo-circle-1',
        'attendance_at': '2026-07-11T08:00:00.000Z',
        'status': studentId == 'demo-student-3' ? 'late' : 'present',
        'created_at': createdAt,
        'updated_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await executor.insert(DatabaseSchema.rewardStore, {
      'id': 'demo-reward-book',
      'name': 'كتاب قصص الأنبياء',
      'description': 'مكافأة تشجيعية للطالب.',
      'token_cost': 25,
      'available_quantity': 5,
      'created_at': createdAt,
      'updated_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await executor.insert(
      DatabaseSchema.walletTransactions,
      {
        'id': 'demo-wallet-credit-1',
        'student_id': 'demo-student-1',
        'amount': 42,
        'transaction_type': 'evaluation',
        'created_at': createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await executor.insert(DatabaseSchema.instituteEvents, {
      'id': 'demo-event-competition',
      'title': 'مسابقة الحفظ الشهرية',
      'description': 'مسابقة تجريبية لأفضل مراجعة.',
      'event_type': 'competition',
      'starts_at': '2026-07-20T09:00:00.000Z',
      'ends_at': '2026-07-20T12:00:00.000Z',
      'created_at': createdAt,
      'updated_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
