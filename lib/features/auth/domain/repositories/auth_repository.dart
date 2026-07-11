import '../../../shared/domain/entities/institute_entities.dart';

abstract interface class AuthRepository {
  Future<InstituteUser?> currentUser();
  Future<void> setCurrentUser(String userId);
  Future<void> clearSession();
  Future<bool> hasPermission({
    required UserRole role,
    required String permissionCode,
  });
}
