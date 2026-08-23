import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';
import 'database_seeder.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async => _database ?? initialize();

  Future<Database> initialize() async {
    if (_database != null) return _database!;

    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, DatabaseSchema.databaseName);
    _database = await openDatabase(
      databasePath,
      version: DatabaseSchema.version,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createVersion1(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        await _migrate(database, oldVersion, newVersion);
      },
    );
    await _database!.transaction(DatabaseSeeder.seedDemoData);
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _createVersion1(Database database) async {
    await database.transaction((transaction) async {
      for (final statement in DatabaseSchema.createStatements) {
        await transaction.execute(statement);
      }
      await DatabaseSeeder.seedRbac(transaction);
      await DatabaseSeeder.seedDemoData(transaction);
    });
  }

  Future<void> _migrate(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await database.transaction((transaction) async {
      if (oldVersion < 1) {
        for (final statement in DatabaseSchema.createStatements) {
          await transaction.execute(statement);
        }
        await DatabaseSeeder.seedRbac(transaction);
      }
      if (oldVersion < 2) {
        for (final statement in DatabaseSchema.migrationV2Statements) {
          await transaction.execute(statement);
        }
        await DatabaseSeeder.seedDemoData(transaction);
      }
      if (oldVersion < 3) {
        for (final statement in DatabaseSchema.migrationV3Statements) {
          await transaction.execute(statement);
        }
        await DatabaseSeeder.seedRbac(transaction);
        await DatabaseSeeder.seedDemoData(transaction);
      }
    });
  }
}
