import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/presentation/cubit/leaderboard_cubit.dart';
import '../../../analytics/presentation/cubit/trend_analysis_cubit.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    required this.leaderboardCubit,
    required this.trendAnalysisCubit,
    super.key,
  });

  final LeaderboardCubit leaderboardCubit;
  final TrendAnalysisCubit trendAnalysisCubit;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    widget.leaderboardCubit.load();
    widget.trendAnalysisCubit.loadStudentsRequiringIntervention();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.leaderboardCubit),
        BlocProvider.value(value: widget.trendAnalysisCubit),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة إدارة المعهد')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportCsv,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('تصدير CSV'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= 900 ? 900 : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('إدارة الحلقات', style: TextStyle(fontSize: 20)),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.groups_outlined),
                      title: Text('الحلقات والمعلمون'),
                      subtitle: Text(
                        'تُضاف واجهة إدارة الحلقات في خطوة الإدارة التالية.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'طلاب يحتاجون متابعة',
                    style: TextStyle(fontSize: 20),
                  ),
                  BlocBuilder<TrendAnalysisCubit, TrendAnalysisState>(
                    builder: (context, state) {
                      if (state.status == TrendAnalysisStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.status == TrendAnalysisStatus.failure) {
                        return Text(
                          state.errorMessage ?? 'تعذر تحميل التحليل.',
                        );
                      }
                      if (state.studentsRequiringIntervention.isEmpty) {
                        return const Text('لا توجد تنبيهات تربوية حالياً.');
                      }
                      return Column(
                        children: [
                          for (final trend
                              in state.studentsRequiringIntervention)
                            ListTile(
                              leading: const Icon(Icons.warning_amber_rounded),
                              title: Text('الطالب: ${trend.studentId}'),
                              subtitle: Text(
                                'هبوط ${trend.degradation.toStringAsFixed(1)} نقاط',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    await widget.leaderboardCubit.load();
    final entries = widget.leaderboardCubit.state.entries;
    final csv = [
      'الترتيب,الطالب,الحلقة,النقاط,المتوسط',
      ...entries.map(
        (entry) =>
            '${entry.rank},${entry.studentName},${entry.circleName},'
            '${entry.totalPoints},${entry.averageScore}',
      ),
    ].join('\n');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('محتوى CSV محلي'),
        content: SingleChildScrollView(child: SelectableText(csv)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
