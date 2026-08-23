import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class PointsTab extends StatelessWidget {
  const PointsTab({
    required this.circleId,
    required this.pointsController,
    required this.selectedStudentId,
    required this.onStudentChanged,
    super.key,
  });

  final String circleId;
  final TextEditingController pointsController;
  final String? selectedStudentId;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'إدارة النقاط',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر طالباً ثم أضف أو أزل نقاطاً من عدّاده داخل الجلسة المفتوحة.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedStudentId,
              decoration: const InputDecoration(labelText: 'الطالب'),
              items: [
                for (final student in state.students)
                  DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      '${student.name} (${state.studentPoints[student.id] ?? 0})',
                    ),
                  ),
              ],
              onChanged: onStudentChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد النقاط'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _apply(context, add: true),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _apply(context, add: false),
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('إزالة'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _apply(BuildContext context, {required bool add}) {
    final amount = int.tryParse(pointsController.text.trim()) ?? 0;
    final studentId = selectedStudentId;
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر طالباً أولاً.')),
      );
      return;
    }
    if (amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عدداً أكبر من صفر.')),
      );
      return;
    }
    context.read<CircleSessionCubit>().awardPointsToStudent(
      circleId: circleId,
      studentId: studentId,
      points: add ? amount : -amount,
      reason: PointReason.award,
      note: add ? 'إضافة نقاط' : 'إزالة نقاط',
    );
    pointsController.text = '0';
  }
}
