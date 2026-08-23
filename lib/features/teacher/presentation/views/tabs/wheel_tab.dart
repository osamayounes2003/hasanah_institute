import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/domain/entities/institute_entities.dart';
import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';
import '../../widgets/islamic_knowledge_wheel.dart';
import '../../widgets/question_reveal_dialog.dart';

class WheelTab extends StatelessWidget {
  const WheelTab({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'عجلة المعرفة',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              '5 أقسام: العقيدة، الفقه، السيرة، الأخلاق، القرآن والتفسير والتجويد.\n'
              'اضغط على العجلة أو الزر — تدور 3 ثوانٍ ثم يُجلب سؤال من التصنيف تحت المؤشر.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            IslamicKnowledgeWheel(
              enabled: !_isSaving(state),
              onSpinComplete: (category) => _onSpinDone(
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

  Future<void> _onSpinDone(
    BuildContext context, {
    required QuestionCategory category,
    required List<InstituteUser> students,
  }) async {
    final cubit = context.read<CircleSessionCubit>();
    final question = await cubit.spinQuestionWheel(
      circleId,
      category: category,
    );
    if (!context.mounted) return;
    if (question == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(category.label),
          content: Text(
            'لا توجد أسئلة في تصنيف «${category.label}».\n'
            'أضف أسئلة من تبويب «أسئلة» لهذا التصنيف أولاً.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestionRevealDialog(
        category: category.label,
        question: question,
        students: students,
        onAward: (studentId, points) {
          cubit.awardPointsToStudent(
            circleId: circleId,
            studentId: studentId,
            points: points,
            reason: PointReason.qa,
            note: 'إجابة عجلة المعرفة — ${category.label}',
          );
        },
      ),
    );
  }
}
