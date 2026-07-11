import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/student_trend.dart';
import '../../domain/repositories/abstract_analytics_repository.dart';

enum TrendAnalysisStatus { initial, loading, success, failure }

class TrendAnalysisState {
  const TrendAnalysisState({
    this.status = TrendAnalysisStatus.initial,
    this.selectedStudentTrend,
    this.studentsRequiringIntervention = const [],
    this.errorMessage,
  });

  final TrendAnalysisStatus status;
  final StudentTrend? selectedStudentTrend;
  final List<StudentTrend> studentsRequiringIntervention;
  final String? errorMessage;

  TrendAnalysisState copyWith({
    TrendAnalysisStatus? status,
    StudentTrend? selectedStudentTrend,
    List<StudentTrend>? studentsRequiringIntervention,
    String? errorMessage,
    bool clearSelectedStudent = false,
    bool clearError = false,
  }) {
    return TrendAnalysisState(
      status: status ?? this.status,
      selectedStudentTrend: clearSelectedStudent
          ? null
          : selectedStudentTrend ?? this.selectedStudentTrend,
      studentsRequiringIntervention:
          studentsRequiringIntervention ?? this.studentsRequiringIntervention,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TrendAnalysisCubit extends Cubit<TrendAnalysisState> {
  TrendAnalysisCubit(this._repository) : super(const TrendAnalysisState());

  final AbstractAnalyticsRepository _repository;

  Future<void> analyzeStudent(String studentId) async {
    emit(state.copyWith(status: TrendAnalysisStatus.loading, clearError: true));
    try {
      final trend = await _repository.calculateStudentTrend(studentId);
      emit(
        state.copyWith(
          status: TrendAnalysisStatus.success,
          selectedStudentTrend: trend,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TrendAnalysisStatus.failure,
          errorMessage: 'تعذر تحليل مستوى الطالب.',
        ),
      );
    }
  }

  Future<void> loadStudentsRequiringIntervention({String? circleId}) async {
    emit(state.copyWith(status: TrendAnalysisStatus.loading, clearError: true));
    try {
      final trends = await _repository.getStudentsRequiringIntervention(
        circleId: circleId,
      );
      emit(
        state.copyWith(
          status: TrendAnalysisStatus.success,
          studentsRequiringIntervention: trends,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TrendAnalysisStatus.failure,
          errorMessage: 'تعذر تحميل قائمة الطلاب المحتاجين للمتابعة.',
        ),
      );
    }
  }
}
