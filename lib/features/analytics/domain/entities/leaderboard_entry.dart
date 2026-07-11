class LeaderboardEntry {
  const LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.circleName,
    required this.totalPoints,
    required this.averageScore,
    required this.rank,
    this.circleId,
  });

  final String studentId;
  final String studentName;
  final String? circleId;
  final String circleName;
  final double totalPoints;
  final double averageScore;
  final int rank;
}
