/// In-memory TTL cache for hot Firestore reads (students, questions, points…).
class AppReadCache {
  AppReadCache({this.ttl = const Duration(minutes: 2)});

  final Duration ttl;
  final _store = <String, ({Object? value, DateTime at})>{};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set(String key, Object? value) {
    _store[key] = (value: value, at: DateTime.now());
  }

  void invalidate(String key) => _store.remove(key);

  void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() => _store.clear();
}
