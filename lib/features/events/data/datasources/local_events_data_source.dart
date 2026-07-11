import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';

class LocalEventsDataSource {
  const LocalEventsDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<Map<String, Object?>>> upcoming({
    required String fromUtcIso8601,
    String? type,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.instituteEvents,
      where: 'starts_at >= ? AND (? IS NULL OR event_type = ?)',
      whereArgs: [fromUtcIso8601, type, type],
      orderBy: 'starts_at ASC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> save(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.instituteEvents,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
