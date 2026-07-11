import '../../domain/entities/token_wallet.dart';
import '../../domain/repositories/abstract_wallet_repository.dart';
import '../datasources/local_wallet_data_source.dart';

class SqliteWalletRepository implements AbstractWalletRepository {
  const SqliteWalletRepository(this._localDataSource);

  final LocalWalletDataSource _localDataSource;

  @override
  Future<void> creditEvaluationTokens({
    required String transactionId,
    required String studentId,
    required int amount,
    required String createdAt,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'يجب أن تكون النقاط موجبة.');
    }
    return _localDataSource.credit({
      'id': transactionId,
      'student_id': studentId,
      'amount': amount,
      'transaction_type': WalletTransactionType.evaluation.name,
      'created_at': createdAt,
    });
  }

  @override
  Future<List<RewardItem>> getAvailableRewards() async {
    final rows = await _localDataSource.availableRewards();
    return rows.map(_rewardFromRow).toList();
  }

  @override
  Future<TokenWallet> getWallet(String studentId) async {
    return TokenWallet(
      studentId: studentId,
      balance: await _localDataSource.balanceForStudent(studentId),
    );
  }

  @override
  Future<void> redeemReward({
    required String transactionId,
    required String studentId,
    required RewardItem reward,
    required String createdAt,
  }) {
    return _localDataSource.redeem(
      rewardId: reward.id,
      expectedCost: reward.tokenCost,
      transaction: {
        'id': transactionId,
        'student_id': studentId,
        'reward_id': reward.id,
        'amount': -reward.tokenCost,
        'transaction_type': WalletTransactionType.redemption.name,
        'created_at': createdAt,
      },
    );
  }

  @override
  Future<void> saveReward(RewardItem reward) {
    return _localDataSource.saveReward({
      'id': reward.id,
      'name': reward.name,
      'description': reward.description,
      'token_cost': reward.tokenCost,
      'available_quantity': reward.availableQuantity,
      'created_at': reward.createdAt,
      'updated_at': reward.updatedAt,
    });
  }

  RewardItem _rewardFromRow(Map<String, Object?> row) {
    return RewardItem(
      id: row['id']! as String,
      name: row['name']! as String,
      description: row['description'] as String?,
      tokenCost: row['token_cost']! as int,
      availableQuantity: row['available_quantity']! as int,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
    );
  }
}
