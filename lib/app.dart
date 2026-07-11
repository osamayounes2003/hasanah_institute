import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/views/admin_dashboard.dart';
import 'features/analytics/data/repositories/sqlite_analytics_repository.dart';
import 'features/analytics/presentation/cubit/leaderboard_cubit.dart';
import 'features/analytics/presentation/cubit/trend_analysis_cubit.dart';
import 'features/auth/data/datasources/local_auth_data_source.dart';
import 'features/auth/data/repositories/sqlite_auth_repository.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';
import 'features/auth/presentation/views/auth_gate_screen.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/student_parent/data/datasources/local_wallet_data_source.dart';
import 'features/student_parent/data/repositories/sqlite_wallet_repository.dart';
import 'features/student_parent/domain/entities/hifz_plan.dart';
import 'features/student_parent/presentation/views/student_parent_portal.dart';
import 'features/teacher/data/datasources/local_teacher_data_source.dart';
import 'features/teacher/data/repositories/sqlite_teacher_repository.dart';
import 'features/teacher/presentation/cubit/attendance_cubit.dart';
import 'features/teacher/presentation/cubit/evaluation_cubit.dart';
import 'features/teacher/presentation/views/teacher_console.dart';

class HasanahApp extends StatefulWidget {
  const HasanahApp({super.key});

  @override
  State<HasanahApp> createState() => _HasanahAppState();
}

class _HasanahAppState extends State<HasanahApp> {
  late final AppDatabase _database;
  late final SessionCubit _sessionCubit;
  late final SqliteAnalyticsRepository _analyticsRepository;
  late final SqliteTeacherRepository _teacherRepository;
  late final SqliteWalletRepository _walletRepository;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.instance;
    _sessionCubit = SessionCubit(
      SqliteAuthRepository(LocalAuthDataSource(_database)),
    );
    _analyticsRepository = SqliteAnalyticsRepository(_database);
    _teacherRepository = SqliteTeacherRepository(
      LocalTeacherDataSource(_database),
    );
    _walletRepository = SqliteWalletRepository(
      LocalWalletDataSource(_database),
    );
  }

  @override
  void dispose() {
    _sessionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoPlan = HifzPlanCalculator.calculate(
      unit: HifzUnit.pages,
      totalUnits: 604,
      completedUnits: 180,
      startDate: DateTime.utc(2026, 7, 11),
      targetDate: DateTime.utc(2027, 1, 1),
      holidays: [DateTime.utc(2026, 7, 17)],
    );
    return MaterialApp(
      title: 'حسنة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthGateScreen(
        sessionCubit: _sessionCubit,
        loginBuilder: (_) => LoginScreen(sessionCubit: _sessionCubit),
        adminBuilder: (_) => AdminDashboard(
          leaderboardCubit: LeaderboardCubit(_analyticsRepository),
          trendAnalysisCubit: TrendAnalysisCubit(_analyticsRepository),
        ),
        teacherBuilder: (_) => TeacherConsole(
          circleId: 'demo-circle-1',
          attendanceCubit: AttendanceCubit(_teacherRepository),
          evaluationCubit: EvaluationCubit(_teacherRepository),
        ),
        studentParentBuilder: (_) => StudentParentPortal(
          studentId: 'demo-student-1',
          hifzPlan: demoPlan,
          walletRepository: _walletRepository,
        ),
      ),
    );
  }
}
