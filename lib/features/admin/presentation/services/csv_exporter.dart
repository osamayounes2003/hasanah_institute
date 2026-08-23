import '../../../analytics/domain/entities/leaderboard_entry.dart';

class CsvExporter {
  const CsvExporter();

  String exportLeaderboard(List<LeaderboardEntry> entries) {
    final rows = <String>[
      'الترتيب,الطالب,الحلقة,النقاط,المتوسط',
      ...entries.map(
        (entry) =>
            '${entry.rank},${entry.studentName},${entry.circleName},'
            '${entry.totalPoints},${entry.averageScore}',
      ),
    ];
    return rows.join('\n');
  }
}
