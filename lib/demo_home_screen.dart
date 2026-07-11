import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'features/analytics/data/repositories/sqlite_analytics_repository.dart';
import 'features/analytics/presentation/cubit/leaderboard_cubit.dart';
import 'features/analytics/presentation/cubit/trend_analysis_cubit.dart';
import 'features/admin/presentation/views/admin_dashboard.dart';
import 'features/student_parent/data/datasources/local_wallet_data_source.dart';
import 'features/student_parent/data/repositories/sqlite_wallet_repository.dart';
import 'features/student_parent/domain/entities/hifz_plan.dart';
import 'features/student_parent/presentation/views/student_parent_portal.dart';
import 'features/teacher/data/datasources/local_teacher_data_source.dart';
import 'features/teacher/data/repositories/sqlite_teacher_repository.dart';
import 'features/teacher/presentation/cubit/attendance_cubit.dart';
import 'features/teacher/presentation/cubit/evaluation_cubit.dart';
import 'features/teacher/presentation/views/teacher_console.dart';

class DemoHomeScreen extends StatelessWidget {
  DemoHomeScreen({super.key});

  final _database = AppDatabase.instance;

  @override
  Widget build(BuildContext context) {
    final analyticsRepository = SqliteAnalyticsRepository(_database);
    final teacherRepository = SqliteTeacherRepository(
      LocalTeacherDataSource(_database),
    );
    final walletRepository = SqliteWalletRepository(
      LocalWalletDataSource(_database),
    );
    final hifzPlan = HifzPlanCalculator.calculate(
      unit: HifzUnit.pages,
      totalUnits: 604,
      completedUnits: 180,
      startDate: DateTime.utc(2026, 7, 11),
      targetDate: DateTime.utc(2027, 1, 1),
      holidays: [DateTime.utc(2026, 7, 17)],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('حسنة - المعاينة التجريبية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'بيانات محلية تجريبية جاهزة للمراجعة',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          _DemoRouteTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'واجهة المدير',
            subtitle: 'التنبيهات التربوية وتصدير CSV',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDashboard(
                  leaderboardCubit: LeaderboardCubit(analyticsRepository),
                  trendAnalysisCubit: TrendAnalysisCubit(analyticsRepository),
                ),
              ),
            ),
          ),
          _DemoRouteTile(
            icon: Icons.school_outlined,
            title: 'واجهة المعلّم',
            subtitle: 'حضور حلقة الفجر والتقييم الثلاثي',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherConsole(
                  circleId: 'demo-circle-1',
                  attendanceCubit: AttendanceCubit(teacherRepository),
                  evaluationCubit: EvaluationCubit(teacherRepository),
                ),
              ),
            ),
          ),
          _DemoRouteTile(
            icon: Icons.auto_stories_outlined,
            title: 'واجهة الطالب وولي الأمر',
            subtitle: 'خطة الحفظ ومحفظة محمد علي',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentParentPortal(
                  studentId: 'demo-student-1',
                  hifzPlan: hifzPlan,
                  walletRepository: walletRepository,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoRouteTile extends StatelessWidget {
  const _DemoRouteTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
