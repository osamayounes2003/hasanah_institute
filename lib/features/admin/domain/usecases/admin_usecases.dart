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
    final fetched = await Future.wait([
      _repository.listStudents(),
      _repository.listTeachers(),
      _repository.listCircles(),
      _repository.statsSnapshot(),
      _repository.listPendingStudentRequests(),
      _repository.allCircleMembers(),
    ]);
    return AdminDashboardData(
      students: fetched[0] as List<InstituteUser>,
      teachers: fetched[1] as List<InstituteUser>,
      circles: fetched[2] as List<Circle>,
      stats: fetched[3] as List<Map<String, Object?>>,
      pendingRequests: fetched[4] as List<StudentJoinRequest>,
      circleMembers: fetched[5] as Map<String, List<InstituteUser>>,
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
