import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/evaluation_record.dart';
import '../../domain/repositories/abstract_teacher_repository.dart';

enum EvaluationSessionStatus { initial, saving, success, failure }

class EvaluationState {
  const EvaluationState({
    this.status = EvaluationSessionStatus.initial,
    this.errorMessage,
  });

  final EvaluationSessionStatus status;
  final String? errorMessage;

  EvaluationState copyWith({
    EvaluationSessionStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EvaluationState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class EvaluationCubit extends Cubit<EvaluationState> {
  EvaluationCubit(this._repository) : super(const EvaluationState());

  final AbstractTeacherRepository _repository;

  Future<void> saveDailyEvaluations(List<EvaluationRecord> evaluations) async {
    if (evaluations.isEmpty) {
      emit(
        state.copyWith(
          status: EvaluationSessionStatus.failure,
          errorMessage: 'أضف تقييماً واحداً على الأقل قبل الحفظ.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: EvaluationSessionStatus.saving, clearError: true),
    );
    try {
      await _repository.insertDailyEvaluations(evaluations);
      emit(state.copyWith(status: EvaluationSessionStatus.success));
    } catch (_) {
      emit(
        state.copyWith(
          status: EvaluationSessionStatus.failure,
          errorMessage: 'تعذر حفظ التقييمات اليومية.',
        ),
      );
    }
  }
}
