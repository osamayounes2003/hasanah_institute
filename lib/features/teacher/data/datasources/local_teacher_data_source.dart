import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';

class LocalTeacherDataSource {
  const LocalTeacherDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<Map<String, Object?>>> circleStudents(String circleId) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT u.id, u.name, u.role, u.parent_id, u.created_at, u.updated_at
        FROM ${DatabaseSchema.users} u
        INNER JOIN ${DatabaseSchema.circleStudents} cs ON cs.student_id = u.id
        WHERE cs.circle_id = ? AND u.role = 'student'
        ORDER BY u.name COLLATE NOCASE ASC
      ''',
      [circleId],
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> saveAttendanceBatch(List<Map<String, Object?>> records) async {
    if (records.isEmpty) return;
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final record in records) {
        batch.insert(
          DatabaseSchema.attendance,
          record,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertEvaluationBatch(
    List<Map<String, Object?>> evaluations,
  ) async {
    if (evaluations.isEmpty) return;
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final evaluation in evaluations) {
        batch.insert(
          DatabaseSchema.evaluations,
          evaluation,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
