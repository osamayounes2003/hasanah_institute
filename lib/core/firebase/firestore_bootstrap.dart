import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreBootstrap {
  FirestoreBootstrap(this._firestore);

  final FirebaseFirestore _firestore;

  /// Ensures baseline admin and sample records exist.
  Future<void> ensureSeedData() async {
    final admin = await getDocPreferCache(
      _firestore.collection(FirestorePaths.users).doc('admin'),
    );
    if (admin.exists) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final batch = _firestore.batch();

    // Disable legacy demo logins that collide on password uniqueness.
    for (final legacyId in ['demo-admin', 'demo-teacher']) {
      batch.set(_firestore.collection(FirestorePaths.users).doc(legacyId), {
        'password': null,
        'updated_at': now,
      }, SetOptions(merge: true));
    }

    // Admin password: 225225 | Sheikh sample password: 123456
    batch.set(_firestore.collection(FirestorePaths.users).doc('admin'), {
      'id': 'admin',
      'name': 'مدير المعهد',
      'role': 'admin',
      'password': '225225',
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));

    batch.set(_firestore.collection(FirestorePaths.users).doc('teacher-1'), {
      'id': 'teacher-1',
      'name': 'الشيخ أحمد',
      'role': 'teacher',
      'password': '123456',
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));

    for (final student in [
      ('student-1', 'محمد علي حسن'),
      ('student-2', 'فاطمة حسن عمر'),
      ('student-3', 'يوسف عمر سعيد'),
    ]) {
      batch.set(_firestore.collection(FirestorePaths.users).doc(student.$1), {
        'id': student.$1,
        'name': student.$2,
        'role': 'student',
        'password': null,
        'created_at': now,
        'updated_at': now,
        'total_points': 0,
      }, SetOptions(merge: true));
    }

    batch.set(_firestore.collection(FirestorePaths.circles).doc('circle-1'), {
      'id': 'circle-1',
      'name': 'حلقة الفجر',
      'teacher_id': 'teacher-1',
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));

    for (final studentId in ['student-1', 'student-2', 'student-3']) {
      final id = 'circle-1_$studentId';
      batch.set(_firestore.collection(FirestorePaths.circleStudents).doc(id), {
        'circle_id': 'circle-1',
        'student_id': studentId,
        'created_at': now,
      }, SetOptions(merge: true));
    }

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
    for (final permission in permissions) {
      batch.set(
        _firestore.collection(FirestorePaths.permissions).doc(permission['id']),
        {...permission, 'code': permission['id'], 'created_at': now},
        SetOptions(merge: true),
      );
    }

    const adminPerms = [
      'manage_users',
      'manage_circles',
      'run_session',
      'edit_attendance',
      'award_points',
      'manage_questions',
      'view_honor_board',
      'export_reports',
    ];
    const teacherPerms = [
      'run_session',
      'edit_attendance',
      'award_points',
      'manage_questions',
      'view_honor_board',
    ];
    for (final code in adminPerms) {
      batch.set(
        _firestore.collection(FirestorePaths.rolePermissions).doc('admin_$code'),
        {'role': 'admin', 'permission_id': code},
        SetOptions(merge: true),
      );
    }
    for (final code in teacherPerms) {
      batch.set(
        _firestore.collection(FirestorePaths.rolePermissions).doc('teacher_$code'),
        {'role': 'teacher', 'permission_id': code},
        SetOptions(merge: true),
      );
    }

    final questions = [
      ('q1', 'ما أول سورة في المصحف؟', 'سورة الفاتحة', 'quran'),
      ('q2', 'ما أركان الإيمان؟', 'ستة أركان', 'aqeedah'),
      ('q3', 'ما أول أركان الإسلام؟', 'الشهادتان', 'fiqh'),
      ('q4', 'أين وُلد النبي ﷺ؟', 'مكة المكرمة', 'seerah'),
      ('q5', 'ما أعظم خلق دعا إليه الإسلام؟', 'الصدق والأمانة', 'akhlaq'),
    ];
    for (final q in questions) {
      batch.set(_firestore.collection(FirestorePaths.qaQuestions).doc(q.$1), {
        'id': q.$1,
        'circle_id': 'circle-1',
        'question': q.$2,
        'answer': q.$3,
        'category': q.$4,
        'pool': 'bank',
        'asked_count': 0,
        'correct_count': 0,
        'points': 0,
        'shown_session_id': '',
        'created_by': 'teacher-1',
        'created_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
