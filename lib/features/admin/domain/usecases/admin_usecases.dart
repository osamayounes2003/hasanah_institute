import '../../../shared/domain/entities/institute_entities.dart';
import '../../../teacher/domain/entities/circle_session_entities.dart';
import '../repositories/abstract_admin_repository.dart';

/// Aggregated admin dashboard snapshot (orchestration belongs in domain).
class AdminDashboardData {
  const AdminDashboardData({
    required this.students,
    required this.teachers,
    required this.circles,
    required this.circleMembers,
    required this.pendingRequests,
    required this.stats,
  });

  final List<InstituteUser> students;
  final List<InstituteUser> teachers;
  final List<Circle> circles;
  final Map<String, List<InstituteUser>> circleMembers;
  final List<StudentJoinRequest> pendingRequests;
  final List<Map<String, Object?>> stats;
}

class LoadAdminDashboardUseCase {
  const LoadAdminDashboardUseCase(this._repository);

  final AbstractAdminRepository _repository;

  Future<AdminDashboardData> call() async {
    final students = await _repository.listStudents();
    final teachers = await _repository.listTeachers();
    final circles = await _repository.listCircles();
    final stats = await _repository.statsSnapshot();
    final pending = await _repository.listPendingStudentRequests();
    final members = <String, List<InstituteUser>>{};
    for (final circle in circles) {
      members[circle.id] = await _repository.circleStudents(circle.id);
    }
    return AdminDashboardData(
      students: students,
      teachers: teachers,
      circles: circles,
      circleMembers: members,
      pendingRequests: pending,
      stats: stats,
    );
  }
}

class SaveStudentUseCase {
  const SaveStudentUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(InstituteUser student) => _repository.saveStudent(student);
}

class DeleteStudentUseCase {
  const DeleteStudentUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(String id) => _repository.deleteStudent(id);
}

class SaveTeacherUseCase {
  const SaveTeacherUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(InstituteUser teacher) => _repository.saveTeacher(teacher);
}

class DeleteTeacherUseCase {
  const DeleteTeacherUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(String id) => _repository.deleteTeacher(id);
}

class SaveCircleUseCase {
  const SaveCircleUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(Circle circle) => _repository.saveCircle(circle);
}

class DeleteCircleUseCase {
  const DeleteCircleUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(String id) => _repository.deleteCircle(id);
}

class AssignStudentToCircleUseCase {
  const AssignStudentToCircleUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call({required String circleId, required String studentId}) {
    return _repository.assignStudentToCircle(
      circleId: circleId,
      studentId: studentId,
    );
  }
}

class RemoveStudentFromCircleAdminUseCase {
  const RemoveStudentFromCircleAdminUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call({required String circleId, required String studentId}) {
    return _repository.removeStudentFromCircle(
      circleId: circleId,
      studentId: studentId,
    );
  }
}

class ApproveStudentRequestUseCase {
  const ApproveStudentRequestUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(String requestId) =>
      _repository.approveStudentRequest(requestId);
}

class RejectStudentRequestUseCase {
  const RejectStudentRequestUseCase(this._repository);
  final AbstractAdminRepository _repository;
  Future<void> call(String requestId) =>
      _repository.rejectStudentRequest(requestId);
}
