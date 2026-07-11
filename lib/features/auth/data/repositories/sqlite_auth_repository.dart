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
  Future<bool> hasPermission({
    required UserRole role,
    required String permissionCode,
  }) {
    return _localDataSource.roleHasPermission(
      role: role.name,
      permissionCode: permissionCode,
    );
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    final user = await _localDataSource.userById(userId);
    if (user == null) {
      throw StateError('Cannot create a session for an unknown user.');
    }
    _currentUserId = userId;
  }

  InstituteUser _userFromRow(Map<String, Object?> row) {
    return InstituteUser(
      id: row['id']! as String,
      name: row['name']! as String,
      role: UserRole.values.byName(row['role']! as String),
      parentId: row['parent_id'] as String?,
      createdAt: IsoDateTime.decode(row['created_at']! as String),
      updatedAt: IsoDateTime.decode(row['updated_at']! as String),
    );
  }
}
