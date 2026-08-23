import '../../../shared/domain/entities/institute_entities.dart';
import '../../../teacher/domain/entities/circle_session_entities.dart'
    show StudentJoinRequest;

abstract interface class AbstractAdminRepository {
  Future<List<InstituteUser>> listStudents();
  Future<void> saveStudent(InstituteUser student);
  Future<void> deleteStudent(String studentId);

  Future<List<InstituteUser>> listTeachers();
  Future<void> saveTeacher(InstituteUser teacher);
  Future<void> deleteTeacher(String teacherId);

  Future<List<Circle>> listCircles();
  Future<void> saveCircle(Circle circle);
  Future<void> deleteCircle(String circleId);
  Future<void> assignStudentToCircle({
    required String circleId,
    required String studentId,
  });
  Future<void> removeStudentFromCircle({
    required String circleId,
    required String studentId,
  });
  Future<List<InstituteUser>> circleStudents(String circleId);

  Future<List<Map<String, Object?>>> statsSnapshot();

  Future<List<StudentJoinRequest>> listPendingStudentRequests();
  Future<void> approveStudentRequest(String requestId);
  Future<void> rejectStudentRequest(String requestId);
}
