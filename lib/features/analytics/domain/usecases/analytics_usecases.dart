import '../entities/leaderboard_entry.dart';
import '../entities/student_trend.dart';
import '../repositories/abstract_analytics_repository.dart';

class GetLeaderboardUseCase {
  const GetLeaderboardUseCase(this._repository);

  final AbstractAnalyticsRepository _repository;

  Future<List<LeaderboardEntry>> call({String? circleId, String? month}) {
    return _repository.getLeaderboard(circleId: circleId, month: month);
  }
}

class CalculateStudentTrendUseCase {
  const CalculateStudentTrendUseCase(this._repository);

  final AbstractAnalyticsRepository _repository;

  Future<StudentTrend> call(String studentId) {
    return _repository.calculateStudentTrend(studentId);
  }
}

class GetInterventionStudentsUseCase {
  const GetInterventionStudentsUseCase(this._repository);

  final AbstractAnalyticsRepository _repository;

  Future<List<StudentTrend>> call({String? circleId}) {
    return _repository.getStudentsRequiringIntervention(circleId: circleId);
  }
}
