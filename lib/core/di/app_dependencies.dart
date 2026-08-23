import 'package:cloud_firestore/cloud_firestore.dart';

import '../cache/app_read_cache.dart';
import '../../features/admin/data/repositories/firestore_admin_repository.dart';
import '../../features/admin/domain/repositories/abstract_admin_repository.dart';
import '../../features/admin/domain/usecases/admin_usecases.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
import '../../features/analytics/data/repositories/firestore_analytics_repository.dart';
import '../../features/analytics/domain/usecases/analytics_usecases.dart';
import '../../features/analytics/presentation/cubit/leaderboard_cubit.dart';
import '../../features/analytics/presentation/cubit/trend_analysis_cubit.dart';
import '../../features/auth/data/repositories/firestore_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/session_usecases.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/teacher/data/repositories/firestore_teacher_repository.dart';
import '../../features/teacher/domain/repositories/abstract_teacher_repository.dart';
import '../../features/teacher/domain/usecases/teacher_session_usecases.dart';
import '../../features/teacher/presentation/cubit/circle_session_cubit.dart';
import '../../features/teacher/presentation/cubit/teacher_bootstrap_cubit.dart';

/// Composition root — wires abstractions → implementations → use cases → Cubits.
class AppDependencies {
  AppDependencies._(this.firestore);

  final FirebaseFirestore firestore;

  factory AppDependencies.create({FirebaseFirestore? firestore}) {
    return AppDependencies._(firestore ?? FirebaseFirestore.instance);
  }

  // ─── Repositories (interfaces) ───────────────────────────────────────────

  late final AuthRepository authRepository = FirestoreAuthRepository(firestore);

  late final AppReadCache readCache = AppReadCache();

  late final AbstractAdminRepository adminRepository =
      FirestoreAdminRepository(firestore, cache: readCache);

  late final AbstractTeacherRepository teacherRepository =
      FirestoreTeacherRepository(firestore, cache: readCache);

  late final FirestoreAnalyticsRepository _analyticsRepository =
      FirestoreAnalyticsRepository(firestore);

  // ─── Auth ────────────────────────────────────────────────────────────────

  late final SessionCubit sessionCubit = SessionCubit(
    restoreSessionUseCase: RestoreSessionUseCase(authRepository),
    signInUseCase: SignInUseCase(authRepository),
    signOutUseCase: SignOutUseCase(authRepository),
  );

  // ─── Admin ───────────────────────────────────────────────────────────────

  AdminCubit createAdminCubit() {
    return AdminCubit(
      loadAdminDashboardUseCase: LoadAdminDashboardUseCase(adminRepository),
      saveStudentUseCase: SaveStudentUseCase(adminRepository),
      deleteStudentUseCase: DeleteStudentUseCase(adminRepository),
      saveTeacherUseCase: SaveTeacherUseCase(adminRepository),
      deleteTeacherUseCase: DeleteTeacherUseCase(adminRepository),
      saveCircleUseCase: SaveCircleUseCase(adminRepository),
      deleteCircleUseCase: DeleteCircleUseCase(adminRepository),
      assignStudentToCircleUseCase: AssignStudentToCircleUseCase(
        adminRepository,
      ),
      removeStudentFromCircleUseCase: RemoveStudentFromCircleAdminUseCase(
        adminRepository,
      ),
      approveStudentRequestUseCase: ApproveStudentRequestUseCase(
        adminRepository,
      ),
      rejectStudentRequestUseCase: RejectStudentRequestUseCase(adminRepository),
    );
  }

  // ─── Teacher ─────────────────────────────────────────────────────────────

  TeacherBootstrapCubit createTeacherBootstrapCubit() {
    return TeacherBootstrapCubit(
      getCircleForTeacherUseCase: GetCircleForTeacherUseCase(teacherRepository),
    );
  }

  /// Teacher workspace Cubit (session + classroom operations).
  CircleSessionCubit createTeacherWorkspaceCubit() {
    return CircleSessionCubit(
      loadCircleStudentsUseCase: LoadCircleStudentsUseCase(teacherRepository),
      getOpenSessionUseCase: GetOpenSessionUseCase(teacherRepository),
      startTeachingSessionUseCase: StartTeachingSessionUseCase(
        teacherRepository,
      ),
      endTeachingSessionUseCase: EndTeachingSessionUseCase(teacherRepository),
      saveDailyAttendanceUseCase: SaveDailyAttendanceUseCase(teacherRepository),
      awardPointsUseCase: AwardPointsUseCase(teacherRepository),
      listQuestionsUseCase: ListQuestionsUseCase(teacherRepository),
      saveQuestionUseCase: SaveQuestionUseCase(teacherRepository),
      deleteQuestionUseCase: DeleteQuestionUseCase(teacherRepository),
      pickRandomQuestionUseCase: PickRandomQuestionUseCase(teacherRepository),
      getHonorBoardUseCase: GetHonorBoardUseCase(teacherRepository),
      listMonthlyPlansUseCase: ListMonthlyPlansUseCase(teacherRepository),
      saveMonthlyPlanUseCase: SaveMonthlyPlanUseCase(teacherRepository),
      deleteMonthlyPlanUseCase: DeleteMonthlyPlanUseCase(teacherRepository),
      studentPointsMapUseCase: StudentPointsMapUseCase(teacherRepository),
      removeStudentFromCircleUseCase: RemoveStudentFromCircleUseCase(
        teacherRepository,
      ),
      listSessionReportsUseCase: ListSessionReportsUseCase(teacherRepository),
      updateSessionDetailsUseCase: UpdateSessionDetailsUseCase(
        teacherRepository,
      ),
      addStudentToCircleUseCase: AddStudentToCircleUseCase(teacherRepository),
      promoteDailyQuestionsUseCase: PromoteDailyQuestionsUseCase(
        teacherRepository,
      ),
    );
  }

  /// Kept for backward-compatible call sites.
  CircleSessionCubit createCircleSessionCubit() => createTeacherWorkspaceCubit();

  // ─── Analytics (available for admin reports) ─────────────────────────────

  LeaderboardCubit createLeaderboardCubit() {
    return LeaderboardCubit(GetLeaderboardUseCase(_analyticsRepository));
  }

  TrendAnalysisCubit createTrendAnalysisCubit() {
    return TrendAnalysisCubit(
      calculateStudentTrendUseCase: CalculateStudentTrendUseCase(
        _analyticsRepository,
      ),
      getInterventionStudentsUseCase: GetInterventionStudentsUseCase(
        _analyticsRepository,
      ),
    );
  }
}
