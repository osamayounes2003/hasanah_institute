import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/presentation/hasanah_request_dialog.dart';
import '../../../../shared/domain/entities/institute_entities.dart';
import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';
import '../../widgets/islamic_knowledge_wheel.dart';
import '../../widgets/question_reveal_dialog.dart';
import '../../widgets/quick_questions_wheel.dart';

class WheelTab extends StatefulWidget {
  const WheelTab({
    required this.circleId,
    required this.teacherId,
    super.key,
  });

  final String circleId;
  final String teacherId;

  @override
  State<WheelTab> createState() => _WheelTabState();
}

class _WheelTabState extends State<WheelTab> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  QuestionCategory _category = QuestionCategory.aqeedah;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        final busy = _isSaving(state);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'عجلة الأسئلة السريعة',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'تدور بلا تخصص، وتختار سؤالاً من الأسئلة اليومية المضافة هنا فقط — وليس من البنك العام.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            QuickQuestionsWheel(
              enabled: !busy,
              onSpinComplete: () => _onDailySpinDone(
                context,
                students: state.students,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _resetDailyWheel(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text('تصفير العجلة'),
            ),
            const SizedBox(height: 16),
            Text(
              'إضافة سؤال يومي',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<QuestionCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'تصنيف السؤال (يُحفظ للبنك العام)',
              ),
              items: [
                for (final category in QuestionCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'الجواب'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      context.read<CircleSessionCubit>().addQuestion(
                        circleId: widget.circleId,
                        teacherId: widget.teacherId,
                        question: _questionController.text,
                        answer: _answerController.text,
                        category: _category,
                        pool: QuestionPool.daily,
                      );
                      _questionController.clear();
                      _answerController.clear();
                    },
              child: const Text('إضافة إلى العجلة اليومية'),
            ),
            const SizedBox(height: 12),
            Text(
              'أسئلة اليوم (${state.dailyQuestions.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.dailyQuestions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('لا توجد أسئلة يومية بعد.'),
              )
            else
              for (final question in state.dailyQuestions)
                Card(
                  child: ListTile(
                    title: Text(question.question),
                    subtitle: Text(
                      '${question.category.label}\n${question.answer}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await HasanahRequestDialog.confirm(
                          context,
                          title: 'تأكيد الحذف',
                          message: 'حذف هذا السؤال اليومي؟',
                          okText: 'حذف',
                        );
                        if (ok && context.mounted) {
                          context.read<CircleSessionCubit>().removeQuestion(
                            question.id,
                            widget.circleId,
                          );
                        }
                      },
                    ),
                  ),
                ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'عجلة المعرفة',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              '5 أقسام: العقيدة، الفقه، السيرة، الأخلاق، القرآن والتفسير والتجويد.\n'
              'تختار سؤالاً من البنك العام حسب التصنيف تحت المؤشر.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            IslamicKnowledgeWheel(
              enabled: !busy,
              onSpinComplete: (category) => _onBankSpinDone(
                context,
                category: category,
                students: state.students,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSaving(CircleSessionState state) =>
      state.status == CircleSessionUiStatus.saving ||
      state.status == CircleSessionUiStatus.loading;

  Future<void> _resetDailyWheel(BuildContext context) async {
    final ok = await HasanahRequestDialog.confirm(
      context,
      title: 'تصفير العجلة اليومية',
      message:
          'سيتم نقل أسئلة اليوم إلى البنك العام مع تصنيفاتها، وتهيئة حقول النقاط بالقيمة 0.',
      okText: 'تصفير ونقل',
    );
    if (ok && context.mounted) {
      await context.read<CircleSessionCubit>().resetDailyWheel(widget.circleId);
    }
  }

  Future<void> _onDailySpinDone(
    BuildContext context, {
    required List<InstituteUser> students,
  }) {
    return _revealQuestion(
      context,
      title: 'سؤال سريع',
      students: students,
      pool: QuestionPool.daily,
    );
  }

  Future<void> _onBankSpinDone(
    BuildContext context, {
    required QuestionCategory category,
    required List<InstituteUser> students,
  }) {
    return _revealQuestion(
      context,
      title: category.label,
      students: students,
      pool: QuestionPool.bank,
      category: category,
    );
  }

  Future<void> _revealQuestion(
    BuildContext context, {
    required String title,
    required List<InstituteUser> students,
    required QuestionPool pool,
    QuestionCategory? category,
  }) async {
    final cubit = context.read<CircleSessionCubit>();
    final question = await cubit.spinQuestionWheel(
      widget.circleId,
      category: category,
      pool: pool,
    );
    if (!context.mounted) return;
    if (question == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestionRevealDialog(
        category: title,
        question: question,
        students: students,
        onAward: (studentId, points) {
          cubit.awardPointsToStudent(
            circleId: widget.circleId,
            studentId: studentId,
            points: points,
            reason: PointReason.qa,
            note: pool == QuestionPool.daily
                ? 'إجابة عجلة الأسئلة السريعة — ${question.category.label}'
                : 'إجابة عجلة المعرفة — ${question.category.label}',
          );
        },
      ),
    );
  }
}
