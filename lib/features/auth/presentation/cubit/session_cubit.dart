import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/usecases/session_usecases.dart';

class SessionCubit extends Cubit<InstituteUser?> {
  SessionCubit({
    required this.restoreSessionUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
  }) : super(null);

  final RestoreSessionUseCase restoreSessionUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;

  Future<void> restore() async {
    emit(await restoreSessionUseCase());
  }

  Future<void> signIn({required String password}) async {
    emit(await signInUseCase(password: password));
  }

  Future<void> signOut() async {
    await signOutUseCase();
    emit(null);
  }
}
