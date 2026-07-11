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
