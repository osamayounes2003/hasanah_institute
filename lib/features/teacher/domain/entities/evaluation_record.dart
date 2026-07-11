class EvaluationRecord {
  EvaluationRecord({
    required this.id,
    required this.studentId,
    required this.circleId,
    required this.evaluatedAt,
    required this.newHifzScore,
    required this.closeReviewScore,
    required this.distantReviewScore,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  }) : assert(newHifzScore >= 0 && newHifzScore <= 10),
       assert(closeReviewScore >= 0 && closeReviewScore <= 10),
       assert(distantReviewScore >= 0 && distantReviewScore <= 10),
       assert(_isUtcIso8601(evaluatedAt)),
       assert(_isUtcIso8601(createdAt)),
       assert(_isUtcIso8601(updatedAt));

  final String id;
  final String studentId;
  final String circleId;
  final String evaluatedAt;
  final double newHifzScore;
  final double closeReviewScore;
  final double distantReviewScore;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  double get averageScore =>
      (newHifzScore + closeReviewScore + distantReviewScore) / 3;

  static bool _isUtcIso8601(String value) {
    return value.endsWith('Z') && DateTime.tryParse(value)?.isUtc == true;
  }
}
