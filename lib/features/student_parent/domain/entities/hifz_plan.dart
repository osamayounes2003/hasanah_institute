enum HifzUnit { pages, verses }

class HifzPlan {
  const HifzPlan({
    required this.unit,
    required this.totalUnits,
    required this.completedUnits,
    required this.remainingUnits,
    required this.availableDays,
    required this.dailyTarget,
    required this.targetDate,
  });

  final HifzUnit unit;
  final int totalUnits;
  final int completedUnits;
  final int remainingUnits;
  final int availableDays;
  final double dailyTarget;
  final DateTime targetDate;

  double get completionRatio =>
      totalUnits == 0 ? 1 : completedUnits / totalUnits;

  /// Raises the daily target when one or more sessions are missed.
  HifzPlan rebalanceAfterMissedSessions(int missedSessions) {
    if (missedSessions <= 0) return this;
    final adjustedDays = (availableDays - missedSessions).clamp(1, 1000000);
    return HifzPlan(
      unit: unit,
      totalUnits: totalUnits,
      completedUnits: completedUnits,
      remainingUnits: remainingUnits,
      availableDays: adjustedDays,
      dailyTarget: remainingUnits == 0 ? 0 : remainingUnits / adjustedDays,
      targetDate: targetDate,
    );
  }
}

abstract final class HifzPlanCalculator {
  static HifzPlan calculate({
    required HifzUnit unit,
    required int totalUnits,
    required int completedUnits,
    required DateTime startDate,
    required DateTime targetDate,
    Iterable<DateTime> holidays = const [],
  }) {
    if (totalUnits < 0 || completedUnits < 0 || completedUnits > totalUnits) {
      throw ArgumentError('قيم الحفظ غير صالحة.');
    }
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final target = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    if (target.isBefore(start)) {
      throw ArgumentError('تاريخ الهدف يجب أن يكون بعد تاريخ البداية.');
    }
    final holidayDays = {
      for (final holiday in holidays)
        DateTime.utc(holiday.year, holiday.month, holiday.day),
    };
    var availableDays = 0;
    for (
      var day = start;
      !day.isAfter(target);
      day = day.add(const Duration(days: 1))
    ) {
      if (!holidayDays.contains(day)) availableDays++;
    }
    if (availableDays == 0 && totalUnits > completedUnits) {
      throw ArgumentError('لا توجد أيام دراسة متاحة ضمن الخطة.');
    }
    final remainingUnits = totalUnits - completedUnits;
    return HifzPlan(
      unit: unit,
      totalUnits: totalUnits,
      completedUnits: completedUnits,
      remainingUnits: remainingUnits,
      availableDays: availableDays,
      dailyTarget: remainingUnits == 0 ? 0 : remainingUnits / availableDays,
      targetDate: target,
    );
  }
}
