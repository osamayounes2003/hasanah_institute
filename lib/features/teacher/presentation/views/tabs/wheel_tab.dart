import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/presentation/hasanah_request_dialog.dart';
import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';
import '../../widgets/islamic_knowledge_wheel.dart';
import '../../widgets/question_reveal_dialog.dart';
import '../../widgets/quick_questions_wheel.dart';

const _categoryColors = <QuestionCategory, Color>{
  QuestionCategory.aqeedah: Color(0xFF0F766E),
  QuestionCategory.fiqh: Color(0xFF7C3AED),
  QuestionCategory.seerah: Color(0xFFB45309),
  QuestionCategory.akhlaq: Color(0xFFBE123C),
  QuestionCategory.quran: Color(0xFF0369A1),
};

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
  bool _dailyMode = true;
  QaQuestion? _pending;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('السريعة'),
              icon: Icon(Icons.flash_on_outlined, size: 18),
            ),
            ButtonSegment(
              value: false,
              label: Text('المعرفة'),
              icon: Icon(Icons.menu_book_outlined, size: 18),
            ),
          ],
          selected: {_dailyMode},
          onSelectionChanged: (value) {
            setState(() => _dailyMode = value.first);
          },
        ),
        const SizedBox(height: 10),
        BlocBuilder<CircleSessionCubit, CircleSessionState>(
          buildWhen: (prev, next) =>
              prev.session?.id != next.session?.id ||
              prev.session?.isOpen != next.session?.isOpen ||
              prev.questions != next.questions,
          builder: (context, state) => _WheelStatusBar(
            dailyMode: _dailyMode,
            state: state,
          ),
        ),
        const SizedBox(height: 8),
        if (_dailyMode) ...[
          QuickQuestionsWheel(
            onBeforeSpin: _drawDaily,
            onSpinComplete: _revealPending,
          ),
          const SizedBox(height: 8),
          BlocBuilder<CircleSessionCubit, CircleSessionState>(
            buildWhen: (prev, next) =>
                prev.status != next.status ||
                prev.questions != next.questions,
            builder: (context, state) {
              final busy = _isSaving(state);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _resetDailyWheel(context),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('تصفير العجلة ونقل الأسئلة للبنك'),
                  ),
                  const SizedBox(height: 4),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'إضافة سؤال يومي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    children: [
                      DropdownButtonFormField<QuestionCategory>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'التصنيف (يُحفظ مع السؤال للبنك)',
                        ),
                        items: [
                          for (final category in QuestionCategory.values)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'نص السؤال',
                        ),
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
                        onPressed: busy ? null : () => _addDaily(context),
                        child: const Text('إضافة إلى العجلة اليومية'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
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
                      _DailyQuestionTile(
                        question: question,
                        shown: question.wasShownIn(state.session?.id ?? ''),
                        busy: busy,
                        onDelete: () => _deleteDaily(context, question),
                      ),
                ],
              );
            },
          ),
        ] else ...[
          const Text(
            'تدور العجلة إلى تصنيف فيه سؤال لم يظهر في هذه الجلسة، ثم يُكشف السؤال.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          IslamicKnowledgeWheel(
            chooseLanding: _drawBank,
            onLanded: (_) => _revealPending(),
          ),
        ],
      ],
    );
  }

  bool _isSaving(CircleSessionState state) =>
      state.status == CircleSessionUiStatus.saving ||
      state.status == CircleSessionUiStatus.loading;

  bool _drawDaily() {
    final result = context.read<CircleSessionCubit>().drawWheelQuestion(
      pool: QuestionPool.daily,
    );
    if (result.error != null) {
      _hint(result.error!);
      return false;
    }
    _pending = result.question;
    return true;
  }

  QuestionCategory? _drawBank() {
    final result = context.read<CircleSessionCubit>().drawWheelQuestion(
      pool: QuestionPool.bank,
    );
    if (result.error != null) {
      _hint(result.error!);
      return null;
    }
    _pending = result.question;
    return result.question!.category;
  }

  Future<void> _revealPending() async {
    final question = _pending;
    _pending = null;
    if (question == null || !mounted) return;
    final cubit = context.read<CircleSessionCubit>();
    cubit.commitDrawnQuestion(question);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestionRevealDialog(
        category: _dailyMode ? 'سؤال سريع' : question.category.label,
        question: question,
        students: cubit.state.students,
        onAward: (studentId, points) {
          cubit.awardPointsToStudent(
            circleId: widget.circleId,
            studentId: studentId,
            points: points,
            reason: PointReason.qa,
            note: _dailyMode
                ? 'إجابة عجلة الأسئلة السريعة — ${question.category.label}'
                : 'إجابة عجلة المعرفة — ${question.category.label}',
          );
        },
      ),
    );
  }

  void _hint(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addDaily(BuildContext context) {
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
  }

  Future<void> _deleteDaily(BuildContext context, QaQuestion question) async {
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
  }

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
}

class _WheelStatusBar extends StatelessWidget {
  const _WheelStatusBar({
    required this.dailyMode,
    required this.state,
  });

  final bool dailyMode;
  final CircleSessionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CircleSessionCubit>();
    final sessionOpen = state.session?.isOpen == true;
    if (dailyMode) {
      final remaining = cubit.remainingCount(pool: QuestionPool.daily);
      final total = cubit.totalCount(pool: QuestionPool.daily);
      return Column(
        children: [
          if (!sessionOpen)
            const _SessionHint(),
          Chip(
            avatar: const Icon(Icons.flash_on_outlined, size: 16),
            label: Text(
              total == 0
                  ? 'لا أسئلة يومية بعد'
                  : remaining == 0
                  ? 'ظهرت كل الأسئلة السريعة ($total)'
                  : 'متبقٍ $remaining من $total',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!sessionOpen) const _SessionHint(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final category in wheelCategories)
              _CategoryRemainingChip(
                category: category,
                remaining: cubit.remainingCount(
                  pool: QuestionPool.bank,
                  category: category,
                ),
                total: cubit.totalCount(
                  pool: QuestionPool.bank,
                  category: category,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SessionHint extends StatelessWidget {
  const _SessionHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'ابدأ الجلسة أولاً حتى تُحسب الأسئلة الظاهرة لهذه الحصة فقط.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _CategoryRemainingChip extends StatelessWidget {
  const _CategoryRemainingChip({
    required this.category,
    required this.remaining,
    required this.total,
  });

  final QuestionCategory category;
  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[category] ?? const Color(0xFF0F766E);
    final exhausted = total > 0 && remaining == 0;
    return Chip(
      backgroundColor: color.withValues(alpha: exhausted ? 0.08 : 0.16),
      label: Text(
        total == 0
            ? '${category.label} — فارغ'
            : '${category.label}  $remaining/$total',
        style: TextStyle(
          fontSize: 12,
          color: exhausted ? Colors.black45 : null,
        ),
      ),
    );
  }
}

class _DailyQuestionTile extends StatelessWidget {
  const _DailyQuestionTile({
    required this.question,
    required this.shown,
    required this.busy,
    required this.onDelete,
  });

  final QaQuestion question;
  final bool shown;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: shown ? 0.55 : 1,
      child: Card(
        child: ListTile(
          title: Text(question.question),
          subtitle: Text('${question.category.label}\n${question.answer}'),
          isThreeLine: true,
          leading: Icon(
            shown ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: shown ? Colors.teal : null,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: busy ? null : onDelete,
          ),
        ),
      ),
    );
  }
}
