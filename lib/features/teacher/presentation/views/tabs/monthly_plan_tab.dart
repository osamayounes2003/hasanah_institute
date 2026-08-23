import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class MonthlyPlanTab extends StatefulWidget {
  const MonthlyPlanTab({
    required this.circleId,
    required this.teacherId,
    super.key,
  });

  final String circleId;
  final String teacherId;

  @override
  State<MonthlyPlanTab> createState() => _MonthlyPlanTabState();
}

class _MonthlyPlanTabState extends State<MonthlyPlanTab>
    with AutomaticKeepAliveClientMixin {
  final _titleController = TextEditingController();
  final _countController = TextEditingController(text: '4');
  var _lessonTitles = <TextEditingController>[];
  var _lessonDates = <DateTime>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rebuildLessonFields(4);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    for (final c in _lessonTitles) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildLessonFields(int count) {
    final old = _lessonTitles;
    _lessonTitles = List.generate(count, (_) => TextEditingController());
    final base = DateTime.now();
    _lessonDates = List.generate(
      count,
      (i) => DateTime(base.year, base.month, base.day).add(Duration(days: i * 7)),
    );
    // Dispose old controllers after this frame so active TextFields are not broken mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in old) {
        c.dispose();
      }
    });
  }

  Future<void> _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _lessonDates[index],
    );
    if (picked == null || !mounted) return;
    setState(() => _lessonDates[index] = picked);
  }

  String _dateLabel(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'الخطة الشهرية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان الخطة'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الدروس المقررة',
                helperText: 'ثم اضغط إعداد الدروس لتعبئة العناوين والتواريخ',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final count = int.tryParse(_countController.text.trim()) ?? 0;
                if (count < 1 || count > 60) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('أدخل عدداً بين 1 و 60.')),
                  );
                  return;
                }
                setState(() => _rebuildLessonFields(count));
              },
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('إعداد دروس الخطة'),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _lessonTitles.length; i++)
              Card(
                key: ValueKey('lesson-field-$i-${_lessonTitles[i].hashCode}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الدرس ${i + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lessonTitles[i],
                        decoration: const InputDecoration(
                          labelText: 'عنوان الدرس',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'التاريخ: ${_dateLabel(_lessonDates[i])}',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickDate(i),
                            icon: const Icon(Icons.event),
                            label: const Text('اختيار'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.status == CircleSessionUiStatus.saving
                    ? null
                    : () async {
                        final count =
                            int.tryParse(_countController.text.trim()) ?? 0;
                        final lessons = [
                          for (var i = 0; i < _lessonTitles.length; i++)
                            PlanLessonItem(
                              id: 'lesson_${i + 1}',
                              title: _lessonTitles[i].text.trim(),
                              date: _dateLabel(_lessonDates[i]),
                            ),
                        ];
                        final saved = await context
                            .read<CircleSessionCubit>()
                            .saveMonthlyPlan(
                              circleId: widget.circleId,
                              teacherId: widget.teacherId,
                              title: _titleController.text,
                              plannedLessonsCount: count,
                              lessons: lessons,
                            );
                        if (saved && mounted) {
                          _titleController.clear();
                          _countController.text = '4';
                          setState(() => _rebuildLessonFields(4));
                        }
                      },
                child: state.status == CircleSessionUiStatus.saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ الخطة الشهرية'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'الخطط المحفوظة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.monthlyPlans.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('لا توجد خطط شهرية بعد.'),
              )
            else
              for (final plan in state.monthlyPlans)
                Card(
                  key: ValueKey(plan.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(plan.title),
                        subtitle: Text(
                          '${plan.plannedLessonsCount} دروس مقررة',
                        ),
                        trailing: IconButton(
                          tooltip: 'حذف الخطة',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: Text('حذف الخطة «${plan.title}»؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              context
                                  .read<CircleSessionCubit>()
                                  .deleteMonthlyPlan(
                                    plan.id,
                                    widget.circleId,
                                  );
                            }
                          },
                        ),
                      ),
                      for (final lesson in plan.lessons)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(lesson.title),
                          trailing: Text(lesson.date),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}
