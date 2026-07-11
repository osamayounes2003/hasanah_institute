import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../../shared/domain/entities/institute_entities.dart';

class SessionCubit extends Cubit<InstituteUser?> {
  SessionCubit(this._authRepository) : super(null);

  final AuthRepository _authRepository;

  Future<void> restore() async {
    emit(await _authRepository.currentUser());
  }

  Future<void> signIn(String userId) async {
    await _authRepository.setCurrentUser(userId);
    await restore();
  }

  Future<void> signOut() async {
    await _authRepository.clearSession();
    emit(null);
  }
}
