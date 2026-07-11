import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';

class LocalWalletDataSource {
  const LocalWalletDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<int> balanceForStudent(String studentId) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        SELECT COALESCE(SUM(amount), 0) AS balance
        FROM ${DatabaseSchema.walletTransactions}
        WHERE student_id = ?
      ''',
      [studentId],
    );
    return (rows.single['balance'] as num).toInt();
  }

  Future<List<Map<String, Object?>>> availableRewards() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseSchema.rewardStore,
      where: 'available_quantity > 0',
      orderBy: 'token_cost ASC, name COLLATE NOCASE',
    );
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Future<void> saveReward(Map<String, Object?> reward) async {
    final database = await _appDatabase.database;
    await database.insert(
      DatabaseSchema.rewardStore,
      reward,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> credit(Map<String, Object?> transaction) async {
    final database = await _appDatabase.database;
    await database.insert(DatabaseSchema.walletTransactions, transaction);
  }

  Future<void> redeem({
    required Map<String, Object?> transaction,
    required String rewardId,
    required int expectedCost,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((transactionDatabase) async {
      final rewards = await transactionDatabase.query(
        DatabaseSchema.rewardStore,
        columns: ['available_quantity', 'token_cost'],
        where: 'id = ?',
        whereArgs: [rewardId],
        limit: 1,
      );
      if (rewards.isEmpty ||
          (rewards.single['available_quantity'] as int) < 1) {
        throw StateError('المكافأة غير متاحة.');
      }
      if (rewards.single['token_cost'] != expectedCost) {
        throw StateError('تكلفة المكافأة تغيّرت.');
      }
      final balanceRows = await transactionDatabase.rawQuery(
        '''
          SELECT COALESCE(SUM(amount), 0) AS balance
          FROM ${DatabaseSchema.walletTransactions}
          WHERE student_id = ?
        ''',
        [transaction['student_id']! as String],
      );
      final currentBalance = (balanceRows.single['balance'] as num).toInt();
      if (currentBalance < expectedCost) {
        throw StateError('رصيد الرموز غير كافٍ.');
      }
      await transactionDatabase.insert(
        DatabaseSchema.walletTransactions,
        transaction,
      );
      await transactionDatabase.update(
        DatabaseSchema.rewardStore,
        {
          'available_quantity':
              (rewards.single['available_quantity'] as int) - 1,
        },
        where: 'id = ?',
        whereArgs: [rewardId],
      );
    });
  }
}
