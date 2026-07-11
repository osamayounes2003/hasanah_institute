import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/abstract_teacher_repository.dart';

enum AttendanceSessionStatus { initial, loading, saving, success, failure }

class AttendanceState {
  const AttendanceState({
    this.status = AttendanceSessionStatus.initial,
    this.circleId,
    this.students = const [],
    this.errorMessage,
  });

  final AttendanceSessionStatus status;
  final String? circleId;
  final List<InstituteUser> students;
  final String? errorMessage;

  AttendanceState copyWith({
    AttendanceSessionStatus? status,
    String? circleId,
    List<InstituteUser>? students,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      circleId: circleId ?? this.circleId,
      students: students ?? this.students,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._repository) : super(const AttendanceState());

  final AbstractTeacherRepository _repository;

  Future<void> loadCircleStudents(String circleId) async {
    emit(
      state.copyWith(
        status: AttendanceSessionStatus.loading,
        circleId: circleId,
        clearError: true,
      ),
    );
    try {
      final students = await _repository.fetchCircleStudents(circleId);
      emit(
        state.copyWith(
          status: AttendanceSessionStatus.initial,
          students: students,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AttendanceSessionStatus.failure,
          errorMessage: 'تعذر تحميل طلاب الحلقة.',
        ),
      );
    }
  }

  Future<void> saveSession(List<AttendanceRecord> records) async {
    final currentCircleId = state.circleId;
    if (currentCircleId == null) {
      emit(
        state.copyWith(
          status: AttendanceSessionStatus.failure,
          errorMessage: 'اختر الحلقة قبل حفظ الحضور.',
        ),
      );
      return;
    }
    if (records.any((record) => record.circleId != currentCircleId)) {
      emit(
        state.copyWith(
          status: AttendanceSessionStatus.failure,
          errorMessage: 'سجلات الحضور لا تطابق الحلقة المحددة.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: AttendanceSessionStatus.saving, clearError: true),
    );
    try {
      await _repository.saveAttendanceList(records);
      emit(state.copyWith(status: AttendanceSessionStatus.success));
    } catch (_) {
      emit(
        state.copyWith(
          status: AttendanceSessionStatus.failure,
          errorMessage: 'تعذر حفظ سجل الحضور.',
        ),
      );
    }
  }
}
