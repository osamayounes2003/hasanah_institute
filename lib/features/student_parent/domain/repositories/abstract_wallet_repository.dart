import '../entities/token_wallet.dart';

abstract interface class AbstractWalletRepository {
  Future<TokenWallet> getWallet(String studentId);
  Future<List<RewardItem>> getAvailableRewards();
  Future<void> saveReward(RewardItem reward);
  Future<void> creditEvaluationTokens({
    required String transactionId,
    required String studentId,
    required int amount,
    required String createdAt,
  });
  Future<void> redeemReward({
    required String transactionId,
    required String studentId,
    required RewardItem reward,
    required String createdAt,
  });
}
