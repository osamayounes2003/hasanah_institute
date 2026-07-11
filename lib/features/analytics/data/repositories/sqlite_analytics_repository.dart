import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/student_trend.dart';
import '../../domain/repositories/abstract_analytics_repository.dart';

class SqliteAnalyticsRepository implements AbstractAnalyticsRepository {
  const SqliteAnalyticsRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<StudentTrend> calculateStudentTrend(String studentId) async {
    final database = await _appDatabase.database;
    final aggregateRows = await database.rawQuery(
      '''
        SELECT
          AVG(
            (new_hifz_score + close_review_score + distant_review_score) / 3.0
          ) AS overall_average,
          COUNT(*) AS evaluation_count
        FROM ${DatabaseSchema.evaluations}
        WHERE student_id = ?
      ''',
      [studentId],
    );
    final recentRows = await database.rawQuery(
      '''
        SELECT
          (new_hifz_score + close_review_score + distant_review_score) / 3.0
            AS session_average
        FROM ${DatabaseSchema.evaluations}
        WHERE student_id = ?
        ORDER BY evaluated_at DESC, id DESC
        LIMIT 4
      ''',
      [studentId],
    );

    final aggregate = aggregateRows.single;
    final count = (aggregate['evaluation_count'] as num?)?.toInt() ?? 0;
    final overallAverage =
        (aggregate['overall_average'] as num?)?.toDouble() ?? 0;
    final movingAverage = recentRows.isEmpty
        ? 0.0
        : recentRows
                  .map((row) => (row['session_average'] as num).toDouble())
                  .reduce((sum, score) => sum + score) /
              recentRows.length;

    return StudentTrend(
      studentId: studentId,
      movingAverage: movingAverage,
      overallAverage: overallAverage,
      evaluationCount: count,
      requiresIntervention: count >= 4 && overallAverage - movingAverage >= 2,
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? circleId,
    String? month,
  }) async {
    _validateMonth(month);
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        WITH evaluation_totals AS (
          SELECT
            e.student_id,
            e.circle_id,
            SUM(
              e.new_hifz_score +
              e.close_review_score +
              e.distant_review_score
            ) AS total_points,
            AVG(
              (
                e.new_hifz_score +
                e.close_review_score +
                e.distant_review_score
              ) / 3.0
            ) AS average_score
          FROM ${DatabaseSchema.evaluations} e
          WHERE
            (? IS NULL OR e.evaluated_at LIKE ? || '%')
            AND (? IS NULL OR e.circle_id = ?)
          GROUP BY e.student_id, e.circle_id
        )
        SELECT
          u.id AS student_id,
          u.name AS student_name,
          et.circle_id,
          COALESCE(c.name, 'غير مسند') AS circle_name,
          et.total_points,
          et.average_score
        FROM evaluation_totals et
        INNER JOIN ${DatabaseSchema.users} u ON u.id = et.student_id
        LEFT JOIN ${DatabaseSchema.circles} c ON c.id = et.circle_id
        WHERE u.role = 'student'
        ORDER BY et.total_points DESC, et.average_score DESC, u.name COLLATE NOCASE
      ''',
      [month, month, circleId, circleId],
    );

    return [
      for (var index = 0; index < rows.length; index++)
        _leaderboardEntryFromRow(rows[index], index + 1),
    ];
  }

  @override
  Future<List<StudentTrend>> getStudentsRequiringIntervention({
    String? circleId,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
        WITH scored_evaluations AS (
          SELECT
            e.student_id,
            (
              e.new_hifz_score +
              e.close_review_score +
              e.distant_review_score
            ) / 3.0 AS session_average,
            ROW_NUMBER() OVER (
              PARTITION BY e.student_id
              ORDER BY e.evaluated_at DESC, e.id DESC
            ) AS session_rank
          FROM ${DatabaseSchema.evaluations} e
          INNER JOIN ${DatabaseSchema.users} u ON u.id = e.student_id
          WHERE u.role = 'student'
        ),
        trend_metrics AS (
          SELECT
            student_id,
            AVG(session_average) AS overall_average,
            AVG(
              CASE WHEN session_rank <= 4 THEN session_average END
            ) AS moving_average,
            COUNT(*) AS evaluation_count
          FROM scored_evaluations
          GROUP BY student_id
        )
        SELECT
          tm.student_id,
          tm.moving_average,
          tm.overall_average,
          tm.evaluation_count
        FROM trend_metrics tm
        WHERE
          tm.evaluation_count >= 4
          AND tm.overall_average - tm.moving_average >= 2
          AND (
            ? IS NULL OR EXISTS (
              SELECT 1
              FROM ${DatabaseSchema.circleStudents} cs
              WHERE cs.student_id = tm.student_id AND cs.circle_id = ?
            )
          )
        ORDER BY tm.overall_average - tm.moving_average DESC
      ''',
      [circleId, circleId],
    );
    return rows.map(_trendFromRow).toList();
  }

  LeaderboardEntry _leaderboardEntryFromRow(
    Map<String, Object?> row,
    int rank,
  ) {
    return LeaderboardEntry(
      studentId: row['student_id']! as String,
      studentName: row['student_name']! as String,
      circleId: row['circle_id'] as String?,
      circleName: row['circle_name']! as String,
      totalPoints: (row['total_points']! as num).toDouble(),
      averageScore: (row['average_score']! as num).toDouble(),
      rank: rank,
    );
  }

  StudentTrend _trendFromRow(Map<String, Object?> row) {
    return StudentTrend(
      studentId: row['student_id']! as String,
      movingAverage: (row['moving_average']! as num).toDouble(),
      overallAverage: (row['overall_average']! as num).toDouble(),
      evaluationCount: (row['evaluation_count']! as num).toInt(),
      requiresIntervention: true,
    );
  }

  void _validateMonth(String? month) {
    if (month != null && !RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      throw ArgumentError.value(
        month,
        'month',
        'يجب أن يكون الشهر بصيغة YYYY-MM.',
      );
    }
  }
}
