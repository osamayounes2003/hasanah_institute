import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/hasanah_request_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/syria_time.dart';
import '../cubit/circle_session_cubit.dart';
import '../widgets/sessions_management_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/honor_board_tab.dart';
import 'tabs/monthly_plan_tab.dart';
import 'tabs/points_tab.dart';
import 'tabs/questions_bank_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/wheel_tab.dart';

class TeacherConsole extends StatefulWidget {
  const TeacherConsole({
    required this.circleId,
    required this.teacherId,
    required this.circleSessionCubit,
    this.circleName,
    this.teacherName,
    this.onSignOut,
    super.key,
  });

  final String circleId;
  final String teacherId;
  final String? circleName;
  final String? teacherName;
  final CircleSessionCubit circleSessionCubit;
  final VoidCallback? onSignOut;

  @override
  State<TeacherConsole> createState() => _TeacherConsoleState();
}

class _TeacherConsoleState extends State<TeacherConsole>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _presentIds = <String>{};
  final _pointsController = TextEditingController(text: '1');
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String? _selectedStudentId;
  var _askedStartSession = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 9, vsync: this);
    widget.circleSessionCubit.bootstrap(
      circleId: widget.circleId,
      teacherId: widget.teacherId,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pointsController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    widget.circleSessionCubit.close();
    super.dispose();
  }

  Future<void> _maybeAskToStartSession(CircleSessionState state) async {
    if (_askedStartSession) return;
    if (state.status != CircleSessionUiStatus.success) return;
    if (state.session?.isOpen == true) {
      _askedStartSession = true;
      return;
    }

    _askedStartSession = true;
    final syriaNow = SyriaTime.display(SyriaTime.dateTimeString());
    if (!mounted) return;

    final start = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء الجلسة'),
        content: Text(
          'هل تريد بدء جلسة الآن؟\n\n'
          'توقيت سوريا الحالي:\n$syriaNow\n\n'
          'يمكنك فتح أكثر من جلسة في نفس اليوم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ابدأ الجلسة'),
          ),
        ],
      ),
    );

    if (start == true && mounted) {
      await widget.circleSessionCubit.startSession(
        circleId: widget.circleId,
        teacherId: widget.teacherId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.circleSessionCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<CircleSessionCubit, CircleSessionState>(
            listenWhen: (prev, next) => prev.status != next.status,
            listener: (context, state) {
              if (state.status == CircleSessionUiStatus.loading ||
                  state.status == CircleSessionUiStatus.saving) {
                HasanahRequestDialog.showLoading(context);
              } else {
                HasanahRequestDialog.hide(context);
              }
            },
          ),
          BlocListener<CircleSessionCubit, CircleSessionState>(
            listenWhen: (prev, next) =>
                prev.message != next.message && next.message != null,
            listener: (context, state) async {
              HasanahRequestDialog.hide(context);
              if (state.status == CircleSessionUiStatus.failure) {
                await HasanahRequestDialog.error(context, state.message!);
              } else {
                await HasanahRequestDialog.success(context, state.message!);
              }
            },
          ),
          BlocListener<CircleSessionCubit, CircleSessionState>(
            listenWhen: (prev, next) =>
                prev.status != next.status &&
                next.status == CircleSessionUiStatus.success,
            listener: (context, state) => _maybeAskToStartSession(state),
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.circleName ?? 'لوحة الشيخ'),
            actions: [
              BlocBuilder<CircleSessionCubit, CircleSessionState>(
                builder: (context, state) {
                  final open = state.session?.isOpen == true;
                  final label = open
                      ? 'جلسة مفتوحة'
                      : state.session == null
                      ? 'لا جلسة'
                      : 'جلسة منتهية';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Chip(
                      avatar: Icon(
                        open ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: open
                            ? HasanahColors.success
                            : HasanahColors.warning,
                      ),
                      label: Text(label),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'الجلسات',
                onPressed: () => _showSessionsSheet(context),
                icon: const Icon(Icons.history_toggle_off_outlined),
              ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_outlined),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const [
                Tab(text: 'الطلاب'),
                Tab(text: 'النقاط'),
                Tab(text: 'أسئلة'),
                Tab(text: 'سريعة'),
                Tab(text: 'معرفة'),
                Tab(text: 'الحضور'),
                Tab(text: 'إدارة الجلسات'),
                Tab(text: 'الخطة الشهرية'),
                Tab(text: 'لوحة الشرف'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              StudentsTab(circleId: widget.circleId),
              PointsTab(
                circleId: widget.circleId,
                pointsController: _pointsController,
                selectedStudentId: _selectedStudentId,
                onStudentChanged: (id) =>
                    setState(() => _selectedStudentId = id),
              ),
              QuestionsBankTab(
                circleId: widget.circleId,
                teacherId: widget.teacherId,
                questionController: _questionController,
                answerController: _answerController,
              ),
              DailyWheelTab(
                circleId: widget.circleId,
                teacherId: widget.teacherId,
              ),
              KnowledgeWheelTab(
                circleId: widget.circleId,
                teacherId: widget.teacherId,
              ),
              AttendanceTab(
                circleId: widget.circleId,
                presentIds: _presentIds,
                onToggle: (studentId, present) {
                  setState(() {
                    if (present) {
                      _presentIds.add(studentId);
                    } else {
                      _presentIds.remove(studentId);
                    }
                  });
                },
              ),
              SessionsManagementTab(circleId: widget.circleId),
              MonthlyPlanTab(
                circleId: widget.circleId,
                teacherId: widget.teacherId,
              ),
              HonorBoardTab(circleId: widget.circleId),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: widget.circleSessionCubit,
          child: BlocBuilder<CircleSessionCubit, CircleSessionState>(
            builder: (context, state) {
              final session = state.session;
              final open = session?.isOpen == true;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الجلسة الحالية',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          open
                              ? Icons.play_circle
                              : session == null
                              ? Icons.pause_circle_outline
                              : Icons.check_circle,
                          color: open
                              ? HasanahColors.primary
                              : session == null
                              ? HasanahColors.warning
                              : HasanahColors.success,
                        ),
                        title: Text(
                          session == null
                              ? 'لا توجد جلسة مفتوحة'
                              : 'جلسة ${SyriaTime.display(session.startedAt)}',
                        ),
                        subtitle: Text(
                          session == null
                              ? 'ابدأ جلسة جديدة في أي وقت (توقيت سوريا).'
                              : open
                              ? 'مفتوحة — يمكنك إنهاؤها ثم بدء جلسة أخرى اليوم'
                              : 'منتهية في ${SyriaTime.display(session.endedAt)}',
                        ),
                        trailing: open
                            ? FilledButton(
                                onPressed: () {
                                  context.read<CircleSessionCubit>().endSession();
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text('إنهاء'),
                              )
                            : FilledButton(
                                onPressed: () {
                                  context.read<CircleSessionCubit>().startSession(
                                    circleId: widget.circleId,
                                    teacherId: widget.teacherId,
                                  );
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text('بدء الجلسة'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحضور والنقاط وإجابات العجلة تُسجَّل داخل الجلسة المفتوحة فقط.',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
