enum WalletTransactionType { evaluation, redemption, adjustment }

class TokenWallet {
  const TokenWallet({required this.studentId, required this.balance});

  final String studentId;
  final int balance;
}

class RewardItem {
  const RewardItem({
    required this.id,
    required this.name,
    required this.tokenCost,
    required this.availableQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final int tokenCost;
  final int availableQuantity;
  final String createdAt;
  final String updatedAt;
}
