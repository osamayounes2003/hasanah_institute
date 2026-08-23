import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../../../teacher/domain/entities/circle_session_entities.dart';
import '../../domain/usecases/admin_usecases.dart';

enum AdminStatus { initial, loading, success, failure }

class AdminState {
  const AdminState({
    this.status = AdminStatus.initial,
    this.students = const [],
    this.teachers = const [],
    this.circles = const [],
    this.circleMembers = const {},
    this.pendingRequests = const [],
    this.stats = const [],
    this.message,
  });

  final AdminStatus status;
  final List<InstituteUser> students;
  final List<InstituteUser> teachers;
  final List<Circle> circles;
  final Map<String, List<InstituteUser>> circleMembers;
  final List<StudentJoinRequest> pendingRequests;
  final List<Map<String, Object?>> stats;
  final String? message;

  AdminState copyWith({
    AdminStatus? status,
    List<InstituteUser>? students,
    List<InstituteUser>? teachers,
    List<Circle>? circles,
    Map<String, List<InstituteUser>>? circleMembers,
    List<StudentJoinRequest>? pendingRequests,
    List<Map<String, Object?>>? stats,
    String? message,
    bool clearMessage = false,
  }) {
    return AdminState(
      status: status ?? this.status,
      students: students ?? this.students,
      teachers: teachers ?? this.teachers,
      circles: circles ?? this.circles,
      circleMembers: circleMembers ?? this.circleMembers,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      stats: stats ?? this.stats,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

/// Presentation orchestrator — depends on use cases only (Clean Architecture).
class AdminCubit extends Cubit<AdminState> {
  AdminCubit({
    required this.loadAdminDashboardUseCase,
    required this.saveStudentUseCase,
    required this.deleteStudentUseCase,
    required this.saveTeacherUseCase,
    required this.deleteTeacherUseCase,
    required this.saveCircleUseCase,
    required this.deleteCircleUseCase,
    required this.assignStudentToCircleUseCase,
    required this.removeStudentFromCircleUseCase,
    required this.approveStudentRequestUseCase,
    required this.rejectStudentRequestUseCase,
  }) : super(const AdminState());

  final LoadAdminDashboardUseCase loadAdminDashboardUseCase;
  final SaveStudentUseCase saveStudentUseCase;
  final DeleteStudentUseCase deleteStudentUseCase;
  final SaveTeacherUseCase saveTeacherUseCase;
  final DeleteTeacherUseCase deleteTeacherUseCase;
  final SaveCircleUseCase saveCircleUseCase;
  final DeleteCircleUseCase deleteCircleUseCase;
  final AssignStudentToCircleUseCase assignStudentToCircleUseCase;
  final RemoveStudentFromCircleAdminUseCase removeStudentFromCircleUseCase;
  final ApproveStudentRequestUseCase approveStudentRequestUseCase;
  final RejectStudentRequestUseCase rejectStudentRequestUseCase;

  Future<void> loadAll() async {
    emit(state.copyWith(status: AdminStatus.loading, clearMessage: true));
    try {
      final data = await loadAdminDashboardUseCase();
      emit(
        state.copyWith(
          status: AdminStatus.success,
          students: data.students,
          teachers: data.teachers,
          circles: data.circles,
          circleMembers: data.circleMembers,
          pendingRequests: data.pendingRequests,
          stats: data.stats,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          message: 'تعذر تحميل بيانات الإدارة.',
        ),
      );
    }
  }

  Future<void> saveStudent(InstituteUser student) {
    return _mutate(
      action: () => saveStudentUseCase(student),
      successMessage: 'تم حفظ الطالب.',
      failureMessage: 'تعذر حفظ الطالب.',
    );
  }

  Future<void> deleteStudent(String id) {
    return _mutate(
      action: () => deleteStudentUseCase(id),
      successMessage: 'تم حذف الطالب.',
      failureMessage: 'تعذر حذف الطالب.',
    );
  }

  Future<void> saveTeacher(InstituteUser teacher) {
    return _mutate(
      action: () => saveTeacherUseCase(teacher),
      successMessage: 'تم حفظ الشيخ.',
      failureMessage: 'تعذر حفظ الشيخ.',
    );
  }

  Future<void> deleteTeacher(String id) {
    return _mutate(
      action: () => deleteTeacherUseCase(id),
      successMessage: 'تم حذف الشيخ.',
      failureMessage: 'تعذر حذف الشيخ.',
    );
  }

  Future<void> saveCircle(Circle circle) {
    return _mutate(
      action: () => saveCircleUseCase(circle),
      successMessage: 'تم حفظ الحلقة.',
      failureMessage: 'تعذر حفظ الحلقة.',
    );
  }

  Future<void> deleteCircle(String id) {
    return _mutate(
      action: () => deleteCircleUseCase(id),
      successMessage: 'تم حذف الحلقة.',
      failureMessage: 'تعذر حذف الحلقة.',
    );
  }

  Future<void> assignStudent({
    required String circleId,
    required String studentId,
  }) {
    return _mutate(
      action: () => assignStudentToCircleUseCase(
        circleId: circleId,
        studentId: studentId,
      ),
      successMessage: 'تم إسناد الطالب للحلقة.',
      failureMessage: 'تعذر إسناد الطالب.',
    );
  }

  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) {
    return _mutate(
      action: () => removeStudentFromCircleUseCase(
        circleId: circleId,
        studentId: studentId,
      ),
      successMessage: 'تم إزالة الطالب من الحلقة.',
      failureMessage: 'تعذر إزالة الطالب.',
    );
  }

  Future<void> approveStudentRequest(String requestId) {
    return _mutate(
      action: () => approveStudentRequestUseCase(requestId),
      successMessage: 'تمت الموافقة وإضافة الطالب للحلقة.',
      failureMessage: 'تعذر الموافقة على الطلب.',
    );
  }

  Future<void> rejectStudentRequest(String requestId) {
    return _mutate(
      action: () => rejectStudentRequestUseCase(requestId),
      successMessage: 'تم رفض الطلب.',
      failureMessage: 'تعذر رفض الطلب.',
    );
  }

  Future<void> _mutate({
    required Future<void> Function() action,
    required String successMessage,
    required String failureMessage,
  }) async {
    emit(state.copyWith(status: AdminStatus.loading, clearMessage: true));
    try {
      await action();
      final data = await loadAdminDashboardUseCase();
      emit(
        state.copyWith(
          status: AdminStatus.success,
          students: data.students,
          teachers: data.teachers,
          circles: data.circles,
          circleMembers: data.circleMembers,
          pendingRequests: data.pendingRequests,
          stats: data.stats,
          message: successMessage,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          message: failureMessage,
        ),
      );
    }
  }
}
