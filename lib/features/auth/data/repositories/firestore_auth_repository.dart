import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/repositories/auth_repository.dart';

class FirestoreAuthRepository implements AuthRepository {
  FirestoreAuthRepository(this._firestore);

  final FirebaseFirestore _firestore;
  String? _currentUserId;

  @override
  Future<void> clearSession() async {
    _currentUserId = null;
  }

  @override
  Future<InstituteUser?> currentUser() async {
    final userId = _currentUserId;
    if (userId == null) return null;
    final snap = await _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return _userFromMap(snap.data()!);
  }

  @override
  Future<bool> hasPermission({
    required UserRole role,
    required String permissionCode,
  }) async {
    final snap = await _firestore
        .collection(FirestorePaths.rolePermissions)
        .where('role', isEqualTo: role.name)
        .get();
    return snap.docs.any(
      (doc) => doc.data()['permission_id'] == permissionCode,
    );
  }

  @override
  Future<InstituteUser> signInWithPassword(String password) async {
    final snap = await _firestore
        .collection(FirestorePaths.users)
        .where('password', isEqualTo: password)
        .get();
    final matches = snap.docs
        .map((doc) => doc.data())
        .where((data) {
          final role = data['role'] as String?;
          return role == 'admin' || role == 'teacher';
        })
        .toList();
    if (matches.isEmpty) {
      throw StateError('كلمة المرور غير صحيحة.');
    }
    if (matches.length > 1) {
      throw StateError(
        'كلمة المرور مستخدمة لأكثر من حساب. غيّرها من لوحة المدير.',
      );
    }
    final data = matches.single;
    _currentUserId = data['id'] as String;
    return _userFromMap(data);
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
