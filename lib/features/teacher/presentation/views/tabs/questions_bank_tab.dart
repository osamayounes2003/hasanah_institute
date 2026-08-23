import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class QuestionsBankTab extends StatefulWidget {
  const QuestionsBankTab({
    required this.circleId,
    required this.teacherId,
    required this.questionController,
    required this.answerController,
    super.key,
  });

  final String circleId;
  final String teacherId;
  final TextEditingController questionController;
  final TextEditingController answerController;

  @override
  State<QuestionsBankTab> createState() => _QuestionsBankTabState();
}

class _QuestionsBankTabState extends State<QuestionsBankTab> {
  QuestionCategory _category = QuestionCategory.aqeedah;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'أسئلة وأجوبة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<QuestionCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'تصنيف السؤال'),
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
              controller: widget.questionController,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.answerController,
              decoration: const InputDecoration(labelText: 'الجواب'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                context.read<CircleSessionCubit>().addQuestion(
                  circleId: widget.circleId,
                  teacherId: widget.teacherId,
                  question: widget.questionController.text,
                  answer: widget.answerController.text,
                  category: _category,
                );
                widget.questionController.clear();
                widget.answerController.clear();
              },
              child: const Text('إضافة سؤال'),
            ),
            const SizedBox(height: 20),
            Text('بنك الأسئلة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.questions.isEmpty)
              const Text('لا توجد أسئلة بعد.')
            else
              for (final question in state.questions)
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
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الحذف'),
                            content: const Text('حذف هذا السؤال؟'),
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
                          context.read<CircleSessionCubit>().removeQuestion(
                            question.id,
                            widget.circleId,
                          );
                        }
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
