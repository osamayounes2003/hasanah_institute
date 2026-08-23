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

class DailyWheelTab extends StatefulWidget {
  const DailyWheelTab({
    required this.circleId,
    required this.teacherId,
    super.key,
  });

  final String circleId;
  final String teacherId;

  @override
  State<DailyWheelTab> createState() => _DailyWheelTabState();
}

class _DailyWheelTabState extends State<DailyWheelTab> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  QuestionCategory _category = QuestionCategory.aqeedah;
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
        Text(
          'عجلة الأسئلة السريعة',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'تختار سؤالاً من الأسئلة اليومية فقط. ظهوره هنا لا يخصم من عجلة المعرفة.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        BlocBuilder<CircleSessionCubit, CircleSessionState>(
          buildWhen: (prev, next) =>
              prev.session?.id != next.session?.id ||
              prev.session?.isOpen != next.session?.isOpen ||
              prev.questions != next.questions,
          builder: (context, state) => _DailyStatusBar(state: state),
        ),
        const SizedBox(height: 8),
        QuickQuestionsWheel(
          onBeforeSpin: _draw,
          onSpinComplete: _reveal,
        ),
        const SizedBox(height: 8),
        BlocBuilder<CircleSessionCubit, CircleSessionState>(
          buildWhen: (prev, next) =>
              prev.status != next.status || prev.questions != next.questions,
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
                      shown: context
                          .read<CircleSessionCubit>()
                          .wasDrawnThisSession(question),
                      busy: busy,
                      onDelete: () => _deleteDaily(context, question),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  bool _draw() {
    final result = context.read<CircleSessionCubit>().drawWheelQuestion(
      pool: QuestionPool.daily,
    );
    if (result.error != null) {
      _hint(context, result.error!);
      return false;
    }
    _pending = result.question;
    return true;
  }

  Future<void> _reveal() {
    return _revealDrawnQuestion(
      context: context,
      pending: _pending,
      onConsumed: () => _pending = null,
      circleId: widget.circleId,
      daily: true,
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

class KnowledgeWheelTab extends StatefulWidget {
  const KnowledgeWheelTab({
    required this.circleId,
    required this.teacherId,
    super.key,
  });

  final String circleId;
  final String teacherId;

  @override
  State<KnowledgeWheelTab> createState() => _KnowledgeWheelTabState();
}

class _KnowledgeWheelTabState extends State<KnowledgeWheelTab> {
  QaQuestion? _pending;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'عجلة المعرفة',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'تختار سؤالاً من البنك العام فقط. ظهوره هنا لا يخصم من العجلة السريعة.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        BlocBuilder<CircleSessionCubit, CircleSessionState>(
          buildWhen: (prev, next) =>
              prev.session?.id != next.session?.id ||
              prev.session?.isOpen != next.session?.isOpen ||
              prev.questions != next.questions,
          builder: (context, state) => _KnowledgeStatusBar(state: state),
        ),
        const SizedBox(height: 8),
        IslamicKnowledgeWheel(
          chooseLanding: _draw,
          onLanded: (_) => _reveal(),
        ),
      ],
    );
  }

  QuestionCategory? _draw() {
    final result = context.read<CircleSessionCubit>().drawWheelQuestion(
      pool: QuestionPool.bank,
    );
    if (result.error != null) {
      _hint(context, result.error!);
      return null;
    }
    _pending = result.question;
    return result.question!.category;
  }

  Future<void> _reveal() {
    return _revealDrawnQuestion(
      context: context,
      pending: _pending,
      onConsumed: () => _pending = null,
      circleId: widget.circleId,
      daily: false,
    );
  }
}

class _DailyStatusBar extends StatelessWidget {
  const _DailyStatusBar({required this.state});

  final CircleSessionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CircleSessionCubit>();
    final remaining = cubit.remainingCount(pool: QuestionPool.daily);
    final total = cubit.totalCount(pool: QuestionPool.daily);
    return Column(
      children: [
        if (state.session?.isOpen != true) const _SessionHint(),
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
}

class _KnowledgeStatusBar extends StatelessWidget {
  const _KnowledgeStatusBar({required this.state});

  final CircleSessionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CircleSessionCubit>();
    final remaining = cubit.remainingCount(pool: QuestionPool.bank);
    final total = cubit.totalCount(pool: QuestionPool.bank);
    return Column(
      children: [
        if (state.session?.isOpen != true) const _SessionHint(),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            total == 0
                ? 'لا أسئلة في البنك العام'
                : remaining == 0
                ? 'ظهرت كل أسئلة البنك ($total)'
                : 'متبقٍ في البنك $remaining من $total',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
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

bool _isSaving(CircleSessionState state) =>
    state.status == CircleSessionUiStatus.saving ||
    state.status == CircleSessionUiStatus.loading;

void _hint(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _revealDrawnQuestion({
  required BuildContext context,
  required QaQuestion? pending,
  required VoidCallback onConsumed,
  required String circleId,
  required bool daily,
}) async {
  onConsumed();
  if (pending == null || !context.mounted) return;
  final cubit = context.read<CircleSessionCubit>();
  cubit.commitDrawnQuestion(pending);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => QuestionRevealDialog(
      category: daily ? 'سؤال سريع' : pending.category.label,
      question: pending,
      students: cubit.state.students,
      onAward: (studentId, points) {
        cubit.awardPointsToStudent(
          circleId: circleId,
          studentId: studentId,
          points: points,
          reason: PointReason.qa,
          note: daily
              ? 'إجابة عجلة الأسئلة السريعة — ${pending.category.label}'
              : 'إجابة عجلة المعرفة — ${pending.category.label}',
        );
      },
    ),
  );
}
