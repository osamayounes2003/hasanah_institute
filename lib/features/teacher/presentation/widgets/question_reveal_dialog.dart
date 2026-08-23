import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/entities/circle_session_entities.dart';

class QuestionRevealDialog extends StatefulWidget {
  const QuestionRevealDialog({
    required this.category,
    required this.question,
    required this.students,
    required this.onAward,
    super.key,
  });

  final String category;
  final QaQuestion question;
  final List<InstituteUser> students;
  final void Function(String studentId, int points) onAward;

  @override
  State<QuestionRevealDialog> createState() => _QuestionRevealDialogState();
}

class _QuestionRevealDialogState extends State<QuestionRevealDialog> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 28),
          const SizedBox(height: 8),
          Text(
            widget.category,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HasanahColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                widget.question.question,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (_showAnswer)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.question.answer,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            else
              const Text(
                'الجواب مخفي — اضغط «عرض الاجابة» عند الحاجة.',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (!_showAnswer)
          FilledButton(
            onPressed: () => setState(() => _showAnswer = true),
            child: const Text('عرض الاجابة'),
          )
        else if (widget.students.isNotEmpty)
          TextButton(
            onPressed: () async {
              await _award(context);
            },
            child: const Text('إسناد نقاط'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Future<void> _award(BuildContext context) async {
    final pointsController = TextEditingController(text: '2');
    String? studentId = widget.students.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نقاط الإجابة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: studentId,
              items: [
                for (final student in widget.students)
                  DropdownMenuItem(
                    value: student.id,
                    child: Text(student.name),
                  ),
              ],
              onChanged: (value) => studentId = value,
              decoration: const InputDecoration(labelText: 'الطالب المجيب'),
            ),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'النقاط'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إسناد'),
          ),
        ],
      ),
    );
    if (confirmed != true || studentId == null || !context.mounted) return;
    final points = int.tryParse(pointsController.text.trim()) ?? 0;
    widget.onAward(studentId!, points);
    Navigator.pop(context);
  }
}
