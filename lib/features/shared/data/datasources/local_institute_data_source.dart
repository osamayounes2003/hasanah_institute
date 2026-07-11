import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';

class LocalInstituteDataSource {
  const LocalInstituteDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> insertCircle(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.circles,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCircleStudent(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.circleStudents,
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertAttendance(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.attendance,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertEvaluation(Map<String, Object?> values) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.evaluations,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> evaluationsForStudent(
    String studentId,
  ) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.evaluations,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'evaluated_at DESC',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }
}
