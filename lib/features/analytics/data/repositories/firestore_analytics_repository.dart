import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/firestore_paths.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/student_trend.dart';
import '../../domain/repositories/abstract_analytics_repository.dart';

/// Analytics backed by Firestore point ledger (honor/points model).
class FirestoreAnalyticsRepository implements AbstractAnalyticsRepository {
  FirestoreAnalyticsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<StudentTrend> calculateStudentTrend(String studentId) async {
    final snap = await _firestore
        .collection(FirestorePaths.pointLedger)
        .where('student_id', isEqualTo: studentId)
        .get();
    final points = snap.docs
        .map((doc) => (doc.data()['points'] as num).toDouble())
        .toList();
    if (points.isEmpty) {
      return StudentTrend(
        studentId: studentId,
        movingAverage: 0,
        overallAverage: 0,
        evaluationCount: 0,
        requiresIntervention: false,
      );
    }
    final overall = points.reduce((a, b) => a + b) / points.length;
    final recent = points.length <= 4
        ? points
        : points.sublist(points.length - 4);
    final moving = recent.reduce((a, b) => a + b) / recent.length;
    return StudentTrend(
      studentId: studentId,
      movingAverage: moving,
      overallAverage: overall,
      evaluationCount: points.length,
      requiresIntervention: points.length >= 4 && overall - moving >= 2,
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    String? circleId,
    String? month,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirestorePaths.pointLedger,
    );
    if (circleId != null) {
      query = query.where('circle_id', isEqualTo: circleId);
    }
    final snap = await query.get();
    final totals = <String, double>{};
    final names = <String, String>{};
    final circles = <String, String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final awardedAt = data['awarded_at'] as String? ?? '';
      if (month != null && !awardedAt.startsWith(month)) continue;
      final studentId = data['student_id'] as String;
      totals[studentId] =
          (totals[studentId] ?? 0) + (data['points'] as num).toDouble();
      circles[studentId] = data['circle_id'] as String? ?? circleId ?? '';
    }

    for (final studentId in totals.keys) {
      final user = await _firestore
          .collection(FirestorePaths.users)
          .doc(studentId)
          .get();
      names[studentId] = user.data()?['name'] as String? ?? studentId;
    }

    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (var index = 0; index < ranked.length; index++)
        LeaderboardEntry(
          studentId: ranked[index].key,
          studentName: names[ranked[index].key] ?? ranked[index].key,
          circleId: circles[ranked[index].key],
          circleName: circles[ranked[index].key] == null ? 'غير مسند' : 'حلقة',
          totalPoints: ranked[index].value,
          averageScore: ranked[index].value,
          rank: index + 1,
        ),
    ];
  }

  @override
  Future<List<StudentTrend>> getStudentsRequiringIntervention({
    String? circleId,
  }) async {
    final users = await _firestore
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: 'student')
        .get();
    final trends = <StudentTrend>[];
    for (final doc in users.docs) {
      final trend = await calculateStudentTrend(doc.id);
      if (trend.requiresIntervention) trends.add(trend);
    }
    trends.sort((a, b) => b.degradation.compareTo(a.degradation));
    return trends;
  }
}
