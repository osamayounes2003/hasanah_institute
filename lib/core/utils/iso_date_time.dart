abstract final class IsoDateTime {
  /// Persists timestamps in the UTC ISO-8601 form expected by SQLite and APIs.
  static String encode(DateTime value) => value.toUtc().toIso8601String();

  static DateTime decode(String value) => DateTime.parse(value).toUtc();
}
