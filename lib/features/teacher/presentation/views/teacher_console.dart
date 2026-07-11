import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart'
    hide AttendanceRecord;
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/evaluation_record.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/evaluation_cubit.dart';

class TeacherConsole extends StatefulWidget {
  const TeacherConsole({
    required this.circleId,
    required this.attendanceCubit,
    required this.evaluationCubit,
    super.key,
  });

  final String circleId;
  final AttendanceCubit attendanceCubit;
  final EvaluationCubit evaluationCubit;

  @override
  State<TeacherConsole> createState() => _TeacherConsoleState();
}

class _TeacherConsoleState extends State<TeacherConsole> {
  final _statuses = <String, AttendanceStatus>{};
  final _scores = <String, List<double>>{};

  @override
  void initState() {
    super.initState();
    widget.attendanceCubit.loadCircleStudents(widget.circleId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.attendanceCubit),
        BlocProvider.value(value: widget.evaluationCubit),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('جلسة المعلّم اليومية')),
        body: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            if (state.status == AttendanceSessionStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AttendanceSessionStatus.failure) {
              return Center(
                child: Text(state.errorMessage ?? 'تعذر تحميل الطلاب.'),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 1100
                        ? 1050
                        : double.infinity,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text(
                        'الحضور اليومي',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: constraints.maxWidth >= 700
                              ? 360
                              : 500,
                          mainAxisExtent: 132,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: state.students.length,
                        itemBuilder: (_, index) =>
                            _attendanceTile(state.students[index]),
                      ),
                      FilledButton(
                        onPressed: () => _saveAttendance(state.students),
                        child: const Text('حفظ الحضور'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'سجل التقييم الثلاثي',
                        style: TextStyle(fontSize: 20),
                      ),
                      for (final student in state.students)
                        _evaluationCard(student),
                      FilledButton(
                        onPressed: () => _saveEvaluations(state.students),
                        child: const Text('حفظ التقييمات'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _attendanceTile(InstituteUser student) {
    final current = _statuses[student.id] ?? AttendanceStatus.present;
    return Card(
      child: ListTile(
        title: Text(student.name),
        trailing: SegmentedButton<AttendanceStatus>(
          segments: const [
            ButtonSegment(value: AttendanceStatus.present, label: Text('حاضر')),
            ButtonSegment(value: AttendanceStatus.late, label: Text('متأخر')),
            ButtonSegment(value: AttendanceStatus.absent, label: Text('غائب')),
          ],
          selected: {current},
          onSelectionChanged: (value) {
            setState(() => _statuses[student.id] = value.first);
          },
        ),
      ),
    );
  }

  Widget _evaluationCard(InstituteUser student) {
    final scores = _scores.putIfAbsent(student.id, () => [0, 0, 0]);
    const labels = ['الحفظ الجديد', 'المراجعة القريبة', 'المراجعة البعيدة'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (var index = 0; index < 3; index++)
              Row(
                children: [
                  Expanded(child: Text(labels[index])),
                  Expanded(
                    child: Slider(
                      value: scores[index],
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: scores[index].toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() => scores[index] = value);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _saveAttendance(List<InstituteUser> students) {
    final now = DateTime.now().toUtc().toIso8601String();
    widget.attendanceCubit.saveSession([
      for (final student in students)
        AttendanceRecord(
          id: 'attendance-${student.id}-$now',
          studentId: student.id,
          circleId: widget.circleId,
          attendanceAt: now,
          status: _statuses[student.id] ?? AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
    ]);
  }

  void _saveEvaluations(List<InstituteUser> students) {
    final now = DateTime.now().toUtc().toIso8601String();
    widget.evaluationCubit.saveDailyEvaluations([
      for (final student in students)
        EvaluationRecord(
          id: 'evaluation-${student.id}-$now',
          studentId: student.id,
          circleId: widget.circleId,
          evaluatedAt: now,
          newHifzScore: _scores[student.id]?[0] ?? 0,
          closeReviewScore: _scores[student.id]?[1] ?? 0,
          distantReviewScore: _scores[student.id]?[2] ?? 0,
          createdAt: now,
          updatedAt: now,
        ),
    ]);
  }
}
