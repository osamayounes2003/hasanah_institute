import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/usecases/teacher_session_usecases.dart';

enum TeacherBootstrapStatus { initial, loading, ready, empty, failure }

class TeacherBootstrapState {
  const TeacherBootstrapState({
    this.status = TeacherBootstrapStatus.initial,
    this.circle,
    this.message,
  });

  final TeacherBootstrapStatus status;
  final Circle? circle;
  final String? message;

  TeacherBootstrapState copyWith({
    TeacherBootstrapStatus? status,
    Circle? circle,
    String? message,
    bool clearCircle = false,
  }) {
    return TeacherBootstrapState(
      status: status ?? this.status,
      circle: clearCircle ? null : circle ?? this.circle,
      message: message,
    );
  }
}

/// Loads the teacher's assigned circle before opening the workspace.
class TeacherBootstrapCubit extends Cubit<TeacherBootstrapState> {
  TeacherBootstrapCubit({
    required this.getCircleForTeacherUseCase,
  }) : super(const TeacherBootstrapState());

  final GetCircleForTeacherUseCase getCircleForTeacherUseCase;

  Future<void> load(String teacherId) async {
    emit(state.copyWith(status: TeacherBootstrapStatus.loading));
    try {
      final circle = await getCircleForTeacherUseCase(teacherId);
      if (circle == null) {
        emit(
          state.copyWith(
            status: TeacherBootstrapStatus.empty,
            clearCircle: true,
            message: 'لم تُسند إليك حلقة بعد.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: TeacherBootstrapStatus.ready,
          circle: circle,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TeacherBootstrapStatus.failure,
          message: 'تعذر تحميل حلقة الشيخ.',
        ),
      );
    }
  }
}
