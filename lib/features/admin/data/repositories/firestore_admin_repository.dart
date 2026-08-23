import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/cache/app_read_cache.dart';
import '../../../../core/firebase/firestore_paths.dart';
import '../../../../core/firebase/firestore_read.dart';
import '../../../shared/domain/entities/institute_entities.dart';
import '../../../teacher/domain/entities/circle_session_entities.dart';
import '../../domain/repositories/abstract_admin_repository.dart';

class FirestoreAdminRepository implements AbstractAdminRepository {
  FirestoreAdminRepository(this._firestore, {AppReadCache? cache})
    : _cache = cache ?? AppReadCache();

  final FirebaseFirestore _firestore;
  final AppReadCache _cache;

  void _invalidateAdmin() {
    _cache.invalidatePrefix('admin:');
    _cache.invalidatePrefix('user:');
    _cache.invalidatePrefix('students:');
    _cache.invalidatePrefix('teacherCircle:');
  }

  @override
  Future<List<InstituteUser>> listStudents() async {
    const key = 'admin:students';
    final cached = _cache.get<List<InstituteUser>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'student'),
    );
    final list = snap.docs.map((d) => _userFromMap(d.data())).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    for (final student in list) {
      _cache.set('user:${student.id}', student);
    }
    _cache.set(key, list);
    return list;
  }

  @override
  Future<void> saveStudent(InstituteUser student) {
    _invalidateAdmin();
    return _firestore.collection(FirestorePaths.users).doc(student.id).set({
      'id': student.id,
      'name': student.name,
      'role': UserRole.student.name,
      'phone': student.phone,
      'password': null,
      'parent_id': student.parentId,
      'created_at': student.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'total_points': student.totalPoints,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    _invalidateAdmin();
    final batch = _firestore.batch();
    batch.delete(_firestore.collection(FirestorePaths.users).doc(studentId));
    final links = await _firestore
        .collection(FirestorePaths.circleStudents)
        .where('student_id', isEqualTo: studentId)
        .get();
    for (final doc in links.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<InstituteUser>> listTeachers() async {
    const key = 'admin:teachers';
    final cached = _cache.get<List<InstituteUser>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'teacher'),
    );
    final list = snap.docs.map((d) => _userFromMap(d.data())).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    for (final teacher in list) {
      _cache.set('user:${teacher.id}', teacher);
    }
    _cache.set(key, list);
    return list;
  }

  @override
  Future<void> saveTeacher(InstituteUser teacher) {
    _invalidateAdmin();
    return _firestore.collection(FirestorePaths.users).doc(teacher.id).set({
      'id': teacher.id,
      'name': teacher.name,
      'role': UserRole.teacher.name,
      'phone': teacher.phone,
      'password': teacher.password,
      'created_at': teacher.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    _invalidateAdmin();
    await _firestore.collection(FirestorePaths.users).doc(teacherId).delete();
  }

  @override
  Future<List<Circle>> listCircles() async {
    const key = 'admin:circles';
    final cached = _cache.get<List<Circle>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore.collection(FirestorePaths.circles),
    );
    final teachers = {for (final t in await listTeachers()) t.id: t.name};
    final list = snap.docs.map((doc) {
      final data = doc.data();
      final teacherId = data['teacher_id'] as String;
      return Circle(
        id: data['id'] as String,
        name: data['name'] as String,
        teacherId: teacherId,
        teacherName: teachers[teacherId],
        createdAt: DateTime.parse(data['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(data['updated_at'] as String).toUtc(),
      );
    }).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    _cache.set(key, list);
    return list;
  }

  @override
  Future<void> saveCircle(Circle circle) {
    _invalidateAdmin();
    return _firestore.collection(FirestorePaths.circles).doc(circle.id).set({
      'id': circle.id,
      'name': circle.name,
      'teacher_id': circle.teacherId,
      'created_at': circle.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCircle(String circleId) async {
    _invalidateAdmin();
    final batch = _firestore.batch();
    batch.delete(_firestore.collection(FirestorePaths.circles).doc(circleId));
    final links = await _firestore
        .collection(FirestorePaths.circleStudents)
        .where('circle_id', isEqualTo: circleId)
        .get();
    for (final doc in links.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> assignStudentToCircle({
    required String circleId,
    required String studentId,
  }) {
    _invalidateAdmin();
    final id = '${circleId}_$studentId';
    return _firestore.collection(FirestorePaths.circleStudents).doc(id).set({
      'circle_id': circleId,
      'student_id': studentId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) {
    _invalidateAdmin();
    return _firestore
        .collection(FirestorePaths.circleStudents)
        .doc('${circleId}_$studentId')
        .delete();
  }

  @override
  Future<List<InstituteUser>> circleStudents(String circleId) async {
    final all = await allCircleMembers();
    return all[circleId] ?? const [];
  }

  @override
  Future<Map<String, List<InstituteUser>>> allCircleMembers() async {
    const key = 'admin:members';
    final cached = _cache.get<Map<String, List<InstituteUser>>>(key);
    if (cached != null) return cached;
    final links = await getQueryPreferCache(
      _firestore.collection(FirestorePaths.circleStudents),
    );
    final ids = {
      for (final doc in links.docs) doc.data()['student_id'] as String,
    };
    final users = await _usersByIds(ids);
    final map = <String, List<InstituteUser>>{};
    for (final doc in links.docs) {
      final data = doc.data();
      final student = users[data['student_id'] as String];
      if (student == null) continue;
      map.putIfAbsent(data['circle_id'] as String, () => []).add(student);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    _cache.set(key, map);
    return map;
  }

  @override
  Future<List<Map<String, Object?>>> statsSnapshot() async {
    const key = 'admin:stats';
    final cached = _cache.get<List<Map<String, Object?>>>(key);
    if (cached != null) return cached;
    final points = await getQueryPreferCache(
      _firestore.collection(FirestorePaths.pointLedger),
    );
    final totals = <String, int>{};
    for (final doc in points.docs) {
      final data = doc.data();
      final studentId = data['student_id'] as String;
      totals[studentId] =
          (totals[studentId] ?? 0) + (data['points'] as num).toInt();
    }
    final users = await _usersByIds(totals.keys);
    final rows = [
      for (final entry in totals.entries)
        {
          'student_id': entry.key,
          'name': users[entry.key]?.name ?? entry.key,
          'points': entry.value,
        },
    ];
    rows.sort(
      (a, b) => ((b['points'] as int).compareTo(a['points'] as int)),
    );
    _cache.set(key, rows);
    return rows;
  }

  @override
  Future<List<StudentJoinRequest>> listPendingStudentRequests() async {
    const key = 'admin:pending';
    final cached = _cache.get<List<StudentJoinRequest>>(key);
    if (cached != null) return cached;
    final snap = await getQueryPreferCache(
      _firestore
          .collection(FirestorePaths.studentRequests)
          .where('status', isEqualTo: StudentRequestStatus.pending.name),
    );
    final list = snap.docs.map((d) => _requestFromMap(d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache.set(key, list);
    return list;
  }

  @override
  Future<void> approveStudentRequest(String requestId) async {
    _invalidateAdmin();
    final ref = _firestore
        .collection(FirestorePaths.studentRequests)
        .doc(requestId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('الطلب غير موجود.');
    }
    final request = _requestFromMap(snap.data()!);
    if (request.status != StudentRequestStatus.pending) {
      throw StateError('تمت معالجة هذا الطلب مسبقاً.');
    }
    final now = DateTime.now().toUtc();
    final studentId = 'student-${now.millisecondsSinceEpoch}';
    final batch = _firestore.batch();
    batch.set(_firestore.collection(FirestorePaths.users).doc(studentId), {
      'id': studentId,
      'name': request.studentName,
      'role': UserRole.student.name,
      'password': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'total_points': 0,
    });
    batch.set(
      _firestore
          .collection(FirestorePaths.circleStudents)
          .doc('${request.circleId}_$studentId'),
      {
        'circle_id': request.circleId,
        'student_id': studentId,
        'created_at': now.toIso8601String(),
      },
    );
    batch.update(ref, {
      'status': StudentRequestStatus.approved.name,
      'updated_at': now.toIso8601String(),
      'approved_student_id': studentId,
    });
    await batch.commit();
  }

  @override
  Future<void> rejectStudentRequest(String requestId) async {
    _invalidateAdmin();
    await _firestore.collection(FirestorePaths.studentRequests).doc(requestId).update({
      'status': StudentRequestStatus.rejected.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, InstituteUser>> _usersByIds(Iterable<String> ids) async {
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
    return found;
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
