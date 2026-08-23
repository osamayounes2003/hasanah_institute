import '../../../shared/domain/entities/institute_entities.dart';

abstract interface class AuthRepository {
  Future<InstituteUser?> currentUser();
  Future<InstituteUser> signInWithPassword(String password);
  Future<void> clearSession();
  Future<bool> hasPermission({
    required UserRole role,
    required String permissionCode,
  });
}
