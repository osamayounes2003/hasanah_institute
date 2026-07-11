class StudentTrend {
  const StudentTrend({
    required this.studentId,
    required this.movingAverage,
    required this.overallAverage,
    required this.evaluationCount,
    required this.requiresIntervention,
  });

  final String studentId;
  final double movingAverage;
  final double overallAverage;
  final int evaluationCount;
  final bool requiresIntervention;

  double get degradation => overallAverage - movingAverage;
}
