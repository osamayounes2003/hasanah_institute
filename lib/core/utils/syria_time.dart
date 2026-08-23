/// Syria local time helpers (`Asia/Damascus`, UTC+3, no DST currently).
abstract final class SyriaTime {
  static const Duration offset = Duration(hours: 3);

  /// Current clock in Syria.
  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// `yyyy-MM-dd` in Syria.
  static String dateString([DateTime? syriaNow]) {
    final t = syriaNow ?? now();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// `yyyy-MM-ddTHH:mm:ss` in Syria (wall clock, no timezone suffix).
  static String dateTimeString([DateTime? syriaNow]) {
    final t = syriaNow ?? now();
    final date = dateString(t);
    final h = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$date'
        'T$h:$min:$s';
  }

  /// Friendly display: `yyyy-MM-dd HH:mm`.
  static String display(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final cleaned = raw.replaceFirst('T', ' ');
    if (cleaned.length >= 16) return cleaned.substring(0, 16);
    if (cleaned.length >= 10) return cleaned.substring(0, 10);
    return cleaned;
  }

  /// Compact id suffix from Syria now: `yyyyMMdd-HHmmss`.
  static String idStamp([DateTime? syriaNow]) {
    final t = syriaNow ?? now();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$y$m$d-$h$min$s';
  }
}
