import '../../../../core/utils/iso_date_time.dart';
import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_data_source.dart';

class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(this._localDataSource);

  final LocalAuthDataSource _localDataSource;
  String? _currentUserId;

  @override
  Future<void> clearSession() async {
    _currentUserId = null;
  }

  @override
  Future<InstituteUser?> currentUser() async {
    final userId = _currentUserId;
    if (userId == null) return null;
    final row = await _localDataSource.userById(userId);
    return row == null ? null : _userFromRow(row);
  }

  @override
  Future<InstituteUser> signInWithPassword(String password) async {
    final match = await _localDataSource.userByPassword(password);
    if (match == null) {
      throw StateError('كلمة المرور غير صحيحة.');
    }
    final role = match['role'] as String?;
    if (role != 'admin' && role != 'teacher') {
      throw StateError('التطبيق متاح للمدير والشيخ فقط.');
    }
    _currentUserId = match['id']! as String;
    return _userFromRow(match);
  }

  @override
  Future<bool> hasPermission({
    required UserRole role,
    required String permissionCode,
  }) {
    return _localDataSource.roleHasPermission(
      role: role.name,
      permissionCode: permissionCode,
    );
  }

  InstituteUser _userFromRow(Map<String, Object?> row) {
    return InstituteUser(
      id: row['id']! as String,
      name: row['name']! as String,
      phone: row['phone'] as String?,
      password: row['password'] as String?,
      role: UserRole.values.byName(row['role']! as String),
      parentId: row['parent_id'] as String?,
      createdAt: IsoDateTime.decode(row['created_at']! as String),
      updatedAt: IsoDateTime.decode(row['updated_at']! as String),
      totalPoints: (row['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}
