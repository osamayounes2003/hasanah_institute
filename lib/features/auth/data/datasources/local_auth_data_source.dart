import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';

class LocalAuthDataSource {
  const LocalAuthDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Map<String, Object?>?> userById(String userId) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.users,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<Map<String, Object?>?> userByPhone(String phone) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.users,
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<Map<String, Object?>?> userByPassword(String password) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.users,
      where: 'password = ? AND role IN (?, ?)',
      whereArgs: [password, 'admin', 'teacher'],
      limit: 2,
    );
    if (rows.isEmpty) return null;
    if (rows.length > 1) {
      throw StateError(
        'كلمة المرور مستخدمة لأكثر من حساب. غيّرها من لوحة المدير.',
      );
    }
    return Map<String, Object?>.from(rows.single);
  }

  Future<bool> roleHasPermission({
    required String role,
    required String permissionCode,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT 1
        FROM ${DatabaseSchema.rolePermissions} rp
        INNER JOIN ${DatabaseSchema.permissions} p
          ON p.id = rp.permission_id
        WHERE rp.role = ? AND p.code = ?
        LIMIT 1
      ''',
      [role, permissionCode],
    );
    return rows.isNotEmpty;
  }
}
