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

  Future<void> saveStudent(InstituteUser student) async {
    try {
      await saveStudentUseCase(student);
      await loadAll();
      emit(state.copyWith(message: 'تم حفظ الطالب.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حفظ الطالب.'));
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await deleteStudentUseCase(id);
      await loadAll();
      emit(state.copyWith(message: 'تم حذف الطالب.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حذف الطالب.'));
    }
  }

  Future<void> saveTeacher(InstituteUser teacher) async {
    try {
      await saveTeacherUseCase(teacher);
      await loadAll();
      emit(state.copyWith(message: 'تم حفظ الشيخ.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حفظ الشيخ.'));
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      await deleteTeacherUseCase(id);
      await loadAll();
      emit(state.copyWith(message: 'تم حذف الشيخ.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حذف الشيخ.'));
    }
  }

  Future<void> saveCircle(Circle circle) async {
    try {
      await saveCircleUseCase(circle);
      await loadAll();
      emit(state.copyWith(message: 'تم حفظ الحلقة.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حفظ الحلقة.'));
    }
  }

  Future<void> deleteCircle(String id) async {
    try {
      await deleteCircleUseCase(id);
      await loadAll();
      emit(state.copyWith(message: 'تم حذف الحلقة.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر حذف الحلقة.'));
    }
  }

  Future<void> assignStudent({
    required String circleId,
    required String studentId,
  }) async {
    try {
      await assignStudentToCircleUseCase(
        circleId: circleId,
        studentId: studentId,
      );
      await loadAll();
      emit(state.copyWith(message: 'تم إسناد الطالب للحلقة.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر إسناد الطالب.'));
    }
  }

  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  }) async {
    try {
      await removeStudentFromCircleUseCase(
        circleId: circleId,
        studentId: studentId,
      );
      await loadAll();
      emit(state.copyWith(message: 'تم إزالة الطالب من الحلقة.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر إزالة الطالب.'));
    }
  }

  Future<void> approveStudentRequest(String requestId) async {
    try {
      await approveStudentRequestUseCase(requestId);
      await loadAll();
      emit(state.copyWith(message: 'تمت الموافقة وإضافة الطالب للحلقة.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر الموافقة على الطلب.'));
    }
  }

  Future<void> rejectStudentRequest(String requestId) async {
    try {
      await rejectStudentRequestUseCase(requestId);
      await loadAll();
      emit(state.copyWith(message: 'تم رفض الطلب.'));
    } catch (_) {
      emit(state.copyWith(message: 'تعذر رفض الطلب.'));
    }
  }
}
