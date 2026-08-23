import '../../../shared/domain/entities/institute_entities.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<InstituteUser?> call() => _repository.currentUser();
}

class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<InstituteUser> call({required String password}) {
    return _repository.signInWithPassword(password);
  }
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.clearSession();
}
