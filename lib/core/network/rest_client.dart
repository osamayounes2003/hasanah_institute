/// Contract to be implemented by the future REST transport layer.
abstract interface class RestClient {
  Future<Map<String, Object?>> get(String path);
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body);
}
