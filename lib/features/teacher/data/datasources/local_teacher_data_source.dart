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

  Future<Map<String, Object?>?> openSession(String circleId) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.teachingSessions,
      where: 'circle_id = ? AND status = ?',
      whereArgs: [circleId, 'open'],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<Map<String, Object?>?> sessionForDate({
    required String circleId,
    required String sessionDate,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.teachingSessions,
      where: 'circle_id = ? AND session_date = ?',
      whereArgs: [circleId, sessionDate],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<void> insertSession(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.teachingSessions,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateSession(String id, Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.update(
      DatabaseSchema.teachingSessions,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, Object?>?> sessionById(String id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.teachingSessions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<void> saveAttendanceWithPoints({
    required List<Map<String, Object?>> attendanceRows,
    required List<Map<String, Object?>> pointRows,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final row in attendanceRows) {
        batch.insert(
          DatabaseSchema.attendance,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in pointRows) {
        batch.insert(
          DatabaseSchema.pointLedger,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertPoint(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(DatabaseSchema.pointLedger, values);
  }

  Future<List<Map<String, Object?>>> questions(String circleId) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.qaQuestions,
      where: 'circle_id = ?',
      whereArgs: [circleId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> upsertQuestion(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.qaQuestions,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeQuestion(String questionId) async {
    final database = await _appDatabase.database;
    await database.delete(
      DatabaseSchema.qaQuestions,
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  Future<Map<String, Object?>?> randomQuestion(String circleId) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT * FROM ${DatabaseSchema.qaQuestions}
        WHERE circle_id = ?
        ORDER BY RANDOM()
        LIMIT 1
      ''',
      [circleId],
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  Future<List<Map<String, Object?>>> honorBoard({
    required String circleId,
    required String fromIso,
    required String toIso,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT
          u.id AS student_id,
          u.name AS student_name,
          COALESCE(SUM(p.points), 0) AS total_points
        FROM ${DatabaseSchema.circleStudents} cs
        INNER JOIN ${DatabaseSchema.users} u ON u.id = cs.student_id
        LEFT JOIN ${DatabaseSchema.pointLedger} p
          ON p.student_id = u.id
         AND p.circle_id = cs.circle_id
         AND p.awarded_at >= ?
         AND p.awarded_at < ?
        WHERE cs.circle_id = ? AND u.role = 'student'
        GROUP BY u.id, u.name
        ORDER BY total_points DESC, u.name COLLATE NOCASE ASC
      ''',
      [fromIso, toIso, circleId],
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<List<Map<String, Object?>>> honorBoardBySession({
    required String circleId,
    required String sessionId,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT
          u.id AS student_id,
          u.name AS student_name,
          COALESCE(SUM(p.points), 0) AS total_points
        FROM ${DatabaseSchema.circleStudents} cs
        INNER JOIN ${DatabaseSchema.users} u ON u.id = cs.student_id
        LEFT JOIN ${DatabaseSchema.pointLedger} p
          ON p.student_id = u.id
         AND p.circle_id = cs.circle_id
         AND p.session_id = ?
        WHERE cs.circle_id = ? AND u.role = 'student'
        GROUP BY u.id, u.name
        ORDER BY total_points DESC, u.name COLLATE NOCASE ASC
      ''',
      [sessionId, circleId],
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }
}
