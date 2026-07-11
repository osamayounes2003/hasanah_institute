import '../entities/leaderboard_entry.dart';
import '../entities/student_trend.dart';

abstract interface class AbstractAnalyticsRepository {
  /// [month] uses the UTC `YYYY-MM` prefix of `evaluated_at`.
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? circleId,
    String? month,
  });

  Future<StudentTrend> calculateStudentTrend(String studentId);

  Future<List<StudentTrend>> getStudentsRequiringIntervention({
    String? circleId,
  });
}
